require 'core'
require 'date'
require 'duration'
require 'time'

require_relative 'base'
require_relative 'models/poll'
require_relative 'models/user'

class Poll < Base
  include Helpers::Guard

  def initialize
    super

    get('/poll/create', ->(req, _) {
      email = require_session(req)
      user = Models::User.find_or_create(email: email)

      form_time = Time.at(Time.now, in: req.timezone)
      return 200, @slim.render('poll/create',
                               user: user,
                               form_time: form_time,
                               group_id: req.params.fetch(:group_id, 0).to_i)
    })

    post('/poll/create', ->(req, resp) {
      email = require_session(req)
      req.params[:email] = email

      choices = req.list_param(:choices, [])
      req.params.delete(:choices)

      begin
        req.params[:expiration] = Time.strptime(
            "#{req.param(:expiration)} UTC",
            '%Y-%m-%dT%H:%M %Z') - req.timezone.current_period.utc_total_offset
      rescue ArgumentError
        return 400, "#{req.param(:expiration)} is invalid date"
      end

      begin
        poll = Models::Poll.create(**req.params.symbolize_keys)
        choices.each { |choice| poll.add_choice(text: choice) }
      rescue Sequel::Error => error
        return 400, error.message
      else
        resp.redirect(poll.url)
      end
    })

    get(%r{^/poll/view/(?<hash_id>.+)$}, ->(req, _) {
      email = require_session(req)
      poll = require_poll(req)

      member = poll.member(email: email)
      return 404, @slim.render('poll/not_found') unless member

      if poll.finished?
        breakdown, unresponded = poll.breakdown
        return 200, @slim.render('poll/finished', poll: poll,
                                                  breakdown: breakdown,
                                                  unresponded: unresponded)
      end

      template = member.responded?(poll_id: poll.id) ? :responded : :view
      return 200, @slim.render("poll/#{template}", poll: poll,
                                                   member: member,
                                                   timezone: req.timezone)
    })

    post('/poll/add_choice', ->(req, _) {
      poll = require_creator(req)
      choice_text = req.param(:choice)

      begin
        poll.add_choice(text: choice_text)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll choice added'
      end
    })

    post('/poll/remove_choice', ->(req, _) {
      poll = require_creator(req)
      choice_text = req.param(:choice)

      choice = poll.choice(text: choice_text)
      unless choice
        return 400, "#{choice_text} is not a choice of #{poll.title}"
      end

      begin
        poll.remove_choice(choice)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll choice removed'
      end
    })

    post('/poll/respond', ->(req, _) {
      poll = require_poll(req)
      email = require_session(req)

      return 405, 'Poll has already finished' if poll.finished?

      member = poll.member(email: email)
      return 404, 'Poll not found' unless member

      if member.responded?(poll_id: poll.id)
        return 409, "Member has already responded to #{poll}"
      end

      begin
        case poll.type
        when :borda_single, :borda_split
          save_borda_poll_response(req, poll, member)
        when :choose_one
          save_choose_one_poll_response(req, member)
        end
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll response added'
      end
    })
  end

  private

  def require_creator(req)
    email = require_session(req)
    poll = require_poll(req)

    unless email == poll.email
      throw(:response, [400, "#{email} is not the creator of #{poll.title}"])
    end

    return poll
  end

  def save_choose_one_poll_response(req, member)
    member.add_response(choice_id: req.param(:choice_id))
  end

  def save_borda_poll_response(req, poll, member)
    responses = req.list_param(:responses)

    if poll.type == :borda_single && responses.length != poll.choices.length
      throw(:response, [400, 'Response set does not match number of choices'])
    end

    responses.each_with_index { |choice_id, rank|
      score = poll.choices.length - rank
      score -= 1 if poll.type == :borda_single
      member.add_response(choice_id: choice_id, data: { score: score })
    }
  end
end
