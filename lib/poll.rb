require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Poll < Base
  include Helpers::Cookie
  include Helpers::Guard

  def initialize
    super
    partials_dir = File.join(Dir.pwd, 'views/poll/partials')
    @slim = Tony::Slim.new(views: 'views',
                           layout: 'views/layout',
                           options: { include_dirs: [partials_dir] })

    get('/poll/create', ->(req, resp) {
      require_email(req, resp)
      resp.write(@slim.render('poll/create'))
    })

    post('/poll/create', ->(req, resp) {
      require_email(req, resp)
      begin
        poll = Models::Poll.create(**req.params.to_h.symbolize_keys)
      rescue Models::ArgumentError, ArgumentError
        resp.status = 406
        resp.write('Not all poll fields provided')
      rescue Sequel::ConstraintViolation
        resp.status = 406
        resp.write('Poll fields cannot be empty')
      else
        resp.redirect(poll.url)
      end
    })

    get(%r{^/poll/view/(?<poll_id>.+)$}, ->(req, resp) {
      poll = require_poll(req, resp)

      if poll.finished?
        resp.write(@slim.render('poll/finished', poll: poll))
        return
      end

      if req.params.key?(:responder)
        responder = poll.responder(salt: req.params.fetch(:responder))
        unless responder
          resp.write(@slim.render('email/get', poll: poll, req: req))
          return
        end

        resp.set_cookie(:email_address, responder.email)
        resp.redirect(poll.url)
        return
      end

      email = fetch_email(req)
      unless email
        resp.write(@slim.render('email/get', poll: poll, req: req))
        return
      end

      responder = poll.responder(email: email)
      unless responder
        resp.write(@slim.render('email/get', poll: poll, req: req))
        return
      end

      timezone = req.cookies.fetch('tz', 'America/Los_Angeles')
      template = responder.responses.empty? ? :view : :responded
      resp.write(@slim.render("poll/#{template}", poll: poll,
                                                  responder: responder,
                                                  timezone: timezone))
    })

    post('/poll/send', ->(req, resp) {
      poll = require_poll(req, resp)

      unless req.params.key?(:email)
        resp.status = 400
        resp.write('No responder provided')
        return
      end

      responder = poll.responder(email: req.params.fetch(:email))
      unless responder
        resp.status = 404
        resp.write(@slim.render('email/responder_not_found'))
        return
      end

      begin
        Utils::Email.email(poll, responder)
      rescue Utils::ArgumentError
        resp.status = 405
        resp.write('Poll has already finished')
        return
      end

      resp.write(@slim.render('email/sent'))
    })

    post('/poll/respond', ->(req, resp) {
      poll = require_poll(req, resp)
      email = require_email(req, resp)

      unless req.params.key?(:responder)
        resp.status = 400
        resp.write('No responder provided')
        return
      end

      responder = poll.responder(salt: req.params.fetch(:responder))
      unless responder
        resp.status = 404
        resp.write('Responder not found')
        return
      end

      if responder.email != email
        resp.status = 405
        resp.write('Logged in user is not the responder in the form')
        return
      end

      unless req.params.key?(:responses)
        resp.status = 400
        resp.write('No responses provided')
        return
      end
      responses = req.params.fetch(:responses)

      if poll.type == :borda_split && !req.params.key?(:bottom_responses)
        resp.status = 400
        resp.write('No bottom response array provided for a borda_split poll')
        return
      end

      bottom_responses = req.params.fetch(:bottom_responses, [])
      unless responses.length + bottom_responses.length == poll.choices.length
        resp.status = 406
        resp.write('Response set does not match number of choices')
        return
      end

      begin
        responses.each_with_index { |choice_id, rank|
          responder.add_response(choice_id: choice_id, rank: rank, chosen: true)
        }
        bottom_responses.each { |choice_id|
          responder.add_response(choice_id: choice_id, chosen: false)
        }
      rescue Sequel::UniqueConstraintViolation
        resp.status = 409
        resp.write('Duplicate response, choice, or rank found')
      rescue Sequel::HookFailed
        resp.status = 405
        resp.write('Poll has already finished')
      else
        resp.status = 201
        resp.write('Poll created')
      end
    })
  end
end
