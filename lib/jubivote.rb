require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'
require 'slim'

Slim::Engine.set_options(
    tabsize: 2,
    pretty: true,
    shortcut: {
      # rubocop:disable Style/StringHashKeys
      '#' => { attr: 'id' },
      '.' => { attr: 'class' },
      '&' => { attr: 'role' },
      '@' => { attr: 'href' }
      # rubocop:enable Style/StringHashKeys
    })

DB = Sequel.sqlite('.data/db.sqlite')
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'admin'
require_relative 'models/poll'

class JubiVote < Sinatra::Base
  helpers Sinatra::ContentFor
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')

  get('/') {
    slim :index
  }

  #####################################
  # POLL
  #####################################
  get('/poll/:poll_id') {
    slim :poll, locals: { poll: Poll[params[:poll_id]] }
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
    poll_id = Admin.create_poll(
        title: params[:title],
        choices: params[:choices].strip.split(/\s*,\s*/),
        responders: params[:responders].strip.split(/\s*,\s*/))
    redirect "/poll/#{poll_id}"
  }

  private

  def slim_admin(template, **options)
    slim(template, **options.merge(views: 'views/admin', layout: :'../layout'))
  end
end
