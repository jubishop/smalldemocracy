require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'
require 'slim'

Slim::Engine.set_options(
    tabsize: 2,
    pretty: ENV.fetch('APP_ENV') == 'development')

DB = Sequel.sqlite('.data/db.sqlite')
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'admin'
require_relative 'models/poll'
require_relative 'models/responder'
require_relative 'utils/email'

class JubiVote < Sinatra::Base
  helpers Sinatra::ContentFor
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')

  get('/') {
    slim :index
  }

  not_found {
    status 404
    slim :not_found
  }

  #####################################
  # POLL
  #####################################
  get('/poll/:poll_id') {
    poll = Poll[params[:poll_id]]
    return not_found unless poll

    unless params.key?(:responder)
      return slim_email(:get_email, locals: { poll: poll })
    end

    responder = poll.responder(salt: params.fetch(:responder))
    return slim_email(:get_email, locals: { poll: poll }) unless responder

    return slim_poll(:poll, locals: { poll: poll, responder: responder })
  }

  post('/send_email') {
    poll = Poll[params[:poll_id]]
    return not_found unless poll

    responder = poll.responder(email: params.fetch(:email))
    return slim_email(:not_found) unless responder

    Email.send_email(poll, responder)
    return slim_email(:sent_email)
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

  post('/admin/create_poll') {
    poll = Admin.create_poll(
        title: params[:title],
        choices: params[:choices].strip.split(/\s*,\s*/),
        responders: params[:responders].strip.split(/\s*,\s*/))
    redirect "/admin/poll/#{poll.id}"
  }

  get('/admin/poll/:poll_id') {
    poll = Poll[params[:poll_id]]
    return not_found unless poll

    slim_admin :poll, locals: { poll: poll }
  }

  private

  def slim_admin(template, **options)
    slim(template, **options.merge(views: 'views/admin', layout: :'../layout'))
  end

  def slim_email(template, **options)
    slim(template, **options.merge(views: 'views/email', layout: :'../layout'))
  end

  def slim_poll(template, **options)
    slim(template, **options.merge(views: 'views/poll', layout: :'../layout'))
  end
end
