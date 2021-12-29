require 'date'

require_relative 'base'
require_relative 'models/choice'
require_relative 'models/poll'

class Poll < Base
  include Helpers::Cookie
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
      require_email(req)
      return 200, @slim.render('poll/create')
    })

    post('/poll/create', ->(req, resp) {
      require_email(req)
      return 400, 'Type must be specified' unless req.params[:type]
      if req.params[:expiration].nil? || req.params[:expiration].empty?
        return 400, 'No expiration date given'
      end

      choices = req.params[:choices]
      req.params.delete(:choices)
      return 400, 'Invalid choices given' unless choices.is_a?(Enumerable)

      choices = choices.compact.delete_if(&:empty?)
      return 400, 'No choices given' if choices.empty?

      hour_offset = req.timezone.utc_offset / 3600
      utc_offset = hour_offset.abs.to_s
      utc_offset.prepend('0') if hour_offset.abs < 10
      utc_offset.prepend(hour_offset >= 0 ? '+' : '-')
      utc_offset += '00'
      date_string = "#{req.params[:expiration]} #{utc_offset}"
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

      member = poll.member(email: email)
      return 404, @slim.render('poll/not_found') unless member

      begin
        case poll.type
        when :borda_single, :borda_split
          save_borda_poll(req, poll, responder)
        when :choose_one
          save_choose_one_poll(req, responder)
        end
      rescue Sequel::UniqueConstraintViolation
        return 409, 'Duplicate response or choice found'
      rescue Sequel::HookFailed => error
        return 400, error.message
      else
        return 201, 'Poll created'
      end
    })
  end

  private

  def save_choose_one_poll(req, responder)
    unless req.params.key?(:choice)
      throw(:response, [400, 'No choice provided'])
    end
    choice_id = req.params.fetch(:choice)
    responder.add_response(choice_id: choice_id)
  end

  def save_borda_poll(req, poll, responder)
    unless req.params.key?(:responses)
      throw(:response, [400, 'No responses provided'])
    end
    responses = req.params.fetch(:responses)

    if poll.type == :borda_split && !req.params.key?(:bottom_responses)
      throw(:response,
            [400, 'No bottom response array provided for a borda_split poll'])
    end

    bottom_responses = req.params.fetch(:bottom_responses, [])
    unless responses.length + bottom_responses.length == poll.choices.length
      throw(:response, [400, 'Response set does not match number of choices'])
    end

    responses.each_with_index { |choice_id, rank|
      score = poll.choices.length - rank
      score -= 1 if poll.type == :borda_single
      responder.add_response(choice_id: choice_id, score: score)
    }
  end
end
