require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Poll < Base
  get('/create') {
    require_email
    return slim_poll(:create)
  }

  post('/create') {
    require_email
    begin
      poll = Models::Poll.create_poll(**params.to_h.symbolize_keys)
    rescue ArgumentError
      halt(406, 'Not all poll fields provided')
    rescue Sequel::CheckConstraintViolation
      halt(406, 'Poll fields cannot be empty')
    end
    return redirect(poll.url)
  }

  get('/view/:poll_id') {
    poll = require_poll

    if (results = poll.results)
      return slim_poll(:finished, locals: { poll: poll, results: results })
    end

    if params.key?(:responder)
      responder = poll.responder(salt: params.fetch(:responder))
      halt(slim_email(:get, locals: { poll: poll })) unless responder

      store_cookie(:email, responder.email)
      return redirect(poll.url)
    end

    email = fetch_email
    halt(slim_email(:get, locals: { poll: poll })) unless email

    responder = poll.responder(email: email)
    halt(slim_email(:get, locals: { poll: poll })) unless responder

    template = responder.responses.empty? ? :view : :responded
    return slim_poll(template, locals: { poll: poll, responder: responder })
  }

  post('/send') {
    poll = require_poll

    halt(400, 'No responder provided') unless params.key?(:email)
    responder = poll.responder(email: params.fetch(:email))
    halt(404, slim_email(:responder_not_found)) unless responder

    Utils::Email.email(poll, responder)
    return slim_email(:sent)
  }

  post('/respond') {
    begin
      @params = JSON.parse(request.body.read).symbolize_keys
    rescue JSON::ParserError
      halt(400, 'Invalid JSON body')
    end

    poll = require_poll

    halt(400, 'No responder provided') unless params.key?(:responder)
    responder = poll.responder(salt: params.fetch(:responder))
    halt(404, 'Responder not found') unless responder

    halt(400, 'No responses provided') unless params.key?(:responses)
    responses = params.fetch(:responses)
    unless responses.length == poll.choices.length
      halt(406, 'Response set does not match number of choices')
    end

    begin
      responses.each_with_index { |choice_id, rank|
        responder.add_response(choice_id: choice_id, rank: rank)
      }
    rescue Sequel::UniqueConstraintViolation
      halt(409, 'Response already exists')
    end

    return 201, 'Poll created'
  }
end
