require 'core'
require 'date'

require_relative 'base'
require_relative 'models/poll'
require_relative 'models/user'

class Poll < Base
  include Helpers::Guard

  def initialize
    super(Tony::Slim.new(views: 'views',
                         layout: 'views/layout',
                         options: {
                           include_dirs: [
                             File.join(Dir.pwd, 'views/poll/partials')
                           ]
                         }))

    get('/poll/create', ->(req, _) {
      email = require_email(req)
      user = Models::User.find_or_create(email: email)

      return 200, @slim.render('poll/create',
                               user: user,
                               group_id: req.params.fetch(:group_id, 0).to_i)
    })

    post('/poll/create', ->(req, resp) {
      email = require_email(req)
      req.params[:email] = email

      choices = list_param(req, :choices)
      req.params.delete(:choices)

      expiration = param(req, :expiration)
      hour_offset = req.timezone.utc_offset / 3600
      utc_offset = hour_offset.abs.to_s
      utc_offset.prepend('0') if hour_offset.abs < 10
      utc_offset.prepend(hour_offset >= 0 ? '+' : '-')
      utc_offset += '00'
      date_string = "#{expiration} #{utc_offset}"
      begin
        # rubocop:disable Style/DateTime
        req.params[:expiration] = DateTime.strptime(
            date_string, '%Y-%m-%dT%H:%M %z').to_time
        # rubocop:enable Style/DateTime
      rescue Date::Error
        return 400, "#{date_string} is invalid date"
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
      email = require_email(req)
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

    post('/poll/respond', ->(req, _) {
      poll = require_poll(req)
      email = require_email(req)

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

  def save_choose_one_poll_response(req, member)
    member.add_response(choice_id: param(req, :choice_id))
  end

  def save_borda_poll_response(req, poll, member)
    responses = list_param(req, :responses)

    if poll.type == :borda_single && responses.length != poll.choices.length
      throw(:response, [400, 'Response set does not match number of choices'])
    end

    responses.each_with_index { |choice_id, rank|
      score = poll.choices.length - rank
      score -= 1 if poll.type == :borda_single
      member.add_response(choice_id: choice_id, score: score)
    }
  end
end
