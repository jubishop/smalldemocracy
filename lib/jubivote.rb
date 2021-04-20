require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class JubiVote < Base
  get('/') {
    slim :index, locals: { email: fetch_email }
  }

  get('/create_poll') {
    require_email
    slim :create_poll
  }

  post('/new_poll') {
    require_email
    poll = Poll.create_poll(**params.to_h.symbolize_keys)
    redirect "/poll/#{poll.id}"
  }

  get('/logout') {
    cookies.delete(:email)
    redirect params.fetch(:r, '/')
  }

  error(Sinatra::NotFound) {
    slim :not_found
  }

  #####################################
  # POLL
  #####################################
  get('/poll/:poll_id') {
    poll = require_poll

    if (results = poll.results)
      return slim_poll(:finished, locals: { poll: poll, results: results })
    end

    if params.key?(:responder)
      responder = poll.responder(salt: params.fetch(:responder))
      halt(slim_email(:get, locals: { poll: poll })) unless responder

      store_cookie(:email, responder.email)
    else
      email = fetch_email
      halt(slim_email(:get, locals: { poll: poll })) unless email

      responder = poll.responder(email: email)
      halt(slim_email(:get, locals: { poll: poll })) unless responder
    end

    template = responder.responses.empty? ? :poll : :responded
    slim_poll(template, locals: { poll: poll, responder: responder })
  }

  post('/send_email') {
    poll = require_poll

    responder = poll.responder(email: params.fetch(:email))
    halt(404, slim_poll(:email_not_found)) unless responder

    logger.info("Now emailing: #{responder.email}")
    Email.send_email(poll, responder)
    return slim_email(:sent)
  }

  post('/poll_response') {
    params = JSON.parse(request.body.read).symbolize_keys

    poll = Poll[params.fetch(:poll_id)]
    halt(404, 'Poll not found') unless poll

    responder = poll.responder(salt: params.fetch(:responder))
    halt(404, 'Responder not found') unless responder

    begin
      params.fetch(:responses).each_with_index { |choice_id, rank|
        responder.add_response(choice_id: choice_id, rank: rank)
      }
    rescue Sequel::UniqueConstraintViolation
      halt(409, 'Response already exists')
    end

    return 201, 'Poll created'
  }

  private

  #####################################
  # SLIM TEMPLATES
  #####################################
  def slim_email(template, **options)
    slim(template, **options.merge(views: 'views/email', layout: :'../layout'))
  end

  def slim_poll(template, **options)
    slim(template, **options.merge(views: 'views/poll', layout: :'../layout'))
  end
end
