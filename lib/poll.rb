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
      expiration_time = form_time + 7.days
      begin
        from = Models::Poll.with_hashid(req.param(:from, nil))
        if from && from.expiration > form_time
          expiration_time = Time.at(from.expiration, in: req.timezone)
        end
      rescue Hashids::InputError
        # Ignore
      end

      return 200, @slim.render('poll/create',
                               user: user,
                               form_time: form_time,
                               expiration_time: expiration_time,
                               group_id: req.params.fetch(:group_id, 0).to_i,
                               from: from)
    })

    post('/poll/create', ->(req, resp) {
      email = require_session(req)
      req.params[:email] = email

      choices = req.list_param(:choices, [])
      req.params.delete(:choices)

      req.params[:expiration] = require_expiration(req)

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
                                                  member: member,
                                                  breakdown: breakdown,
                                                  unresponded: unresponded,
                                                  timezone: req.timezone)
      end

      template = member.responded?(poll_id: poll.id) ? :responded : :view
      return 200, @slim.render("poll/#{template}", poll: poll,
                                                   member: member,
                                                   timezone: req.timezone)
    })

    get(%r{^/poll/edit/(?<hash_id>.+)$}, ->(req, resp) {
      poll = catch(:response) { require_creator(req) }

      if poll.is_a?(Models::Poll)
        expiration_time = Time.at(poll.expiration, in: req.timezone)
        form_time = Time.at(Time.now, in: req.timezone)

        return 200, @slim.render('poll/edit', poll: poll,
                                              expiration_time: expiration_time,
                                              form_time: form_time)
      end

      resp.redirect(require_poll(req).url)
    })

    post('/poll/title', ->(req, _) {
      poll = require_editable_poll(req)
      title = req.param(:title)

      begin
        poll.update(title: title)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll title changed'
      end
    })

    post('/poll/question', ->(req, _) {
      poll = require_editable_poll(req)
      question = req.param(:question)

      begin
        poll.update(question: question)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll question changed'
      end
    })

    post('/poll/add_choice', ->(req, _) {
      poll = require_editable_poll(req)
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
      poll = require_editable_poll(req)
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

    post('/poll/remove_responses', ->(req, _) {
      email = require_session(req)
      poll = require_poll(req)

      member = poll.member(email: email)
      return 401, "#{email} is not a responder of #{poll}" unless member

      begin
        poll.remove_responses(member_id: member.id)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll member responses removed'
      end
    })

    post('/poll/expiration', ->(req, _) {
      poll = require_creator(req)

      begin
        poll.update(expiration: require_expiration(req))
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll expiration updated'
      end
    })

    post('/poll/destroy', ->(req, _) {
      poll = require_creator(req)

      begin
        poll.destroy
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Poll destroyed'
      end
    })

    post('/poll/respond', ->(req, _) {
      email = require_session(req)
      poll = require_poll(req)

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

  def require_editable_poll(req)
    poll = require_creator(req)

    if poll.any_response?
      throw(:response, [400, "#{poll.title} already has responses"])
    end

    return poll
  end

  def require_creator(req)
    email = require_session(req)
    poll = require_poll(req)

    unless email == poll.email
      throw(:response, [401, "#{email} is not the creator of #{poll.title}"])
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
