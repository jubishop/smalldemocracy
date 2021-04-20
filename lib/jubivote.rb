require 'core'
require 'linguistics'
require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/static'
require 'slim'
require 'slim/include'

Linguistics.use(:en)

Slim::Engine.set_options(
    tabsize: 2,
    include_dirs: ["#{Dir.pwd}/views/partials"],
    pretty: ENV.fetch('APP_ENV') == 'development')

DB = Sequel.sqlite('.data/db.sqlite')
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'models/poll'
require_relative 'models/responder'
require_relative 'utils/crypt'
require_relative 'utils/email'

class JubiVote < Sinatra::Base
  helpers Sinatra::ContentFor
  helpers Sinatra::Cookies
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')
  set(:cookie_options, expires: Time.at(2**31 - 1))

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

  #####################################
  # ADMIN
  #####################################
  get('/admin') {
    slim_admin :admin
  }

  get('/admin/create_poll') {
    slim_admin :create_poll
  }

  post('/admin/new_poll') {
    poll = Poll.create_poll(**params.to_h.symbolize_keys)
    redirect "/admin/poll/#{poll.id}"
  }

  get('/admin/poll/:poll_id') {
    poll = require_poll

    slim_admin :poll, locals: { poll: poll }
  }

  private

  #####################################
  # SLIM TEMPLATES
  #####################################
  def slim_admin(template, **options)
    slim(template, **options.merge(views: 'views/admin', layout: :'../layout'))
  end

  def slim_email(template, **options)
    slim(template, **options.merge(views: 'views/email', layout: :'../layout'))
  end

  def slim_poll(template, **options)
    slim(template, **options.merge(views: 'views/poll', layout: :'../layout'))
  end

  #####################################
  # REQUIRE GUARDS
  #####################################
  def require_poll
    poll = Poll[params.fetch(:poll_id)]
    halt(404, slim_poll(:not_found)) unless poll
    return poll
  end

  def require_email
    email = fetch_email
    halt(404, slim_email(:not_found)) unless email
    return email
  end

  #####################################
  # COOKIES
  #####################################
  def fetch_email
    email = fetch_cookie(:email)
    return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
  end

  def store_cookie(key, value)
    cookies[key] = Crypt.en(value)
  end

  def fetch_cookie(key)
    return unless cookies.key?(key)

    return Crypt.de(cookies.fetch(key))
  end
end
