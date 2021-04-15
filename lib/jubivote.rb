require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

DB = Sequel.sqlite('.data/db.sqlite')
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'admin'
require_relative 'helpers/head_tags'
require_relative 'models/poll'

class JubiVote < Sinatra::Base
  helpers Sinatra::ContentFor
  helpers Sinatra::HeadTags
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')

  get('/') {
    slim :index
  }

  get('/poll/:poll_id') {
    slim :poll, locals: { poll: Poll[params[:poll_id]] }
  }

  #####################################
  # ADMIN
  #####################################
  get('/admin') {
    slim :admin
  }

  get('/admin/create_poll') {
    slim :create_poll
  }

  post('/admin/create_poll') {
    poll_id = Admin.create_poll(
        title: params[:title],
        choices: params[:choices].strip.split(/\s*,\s*/),
        responders: params[:responders].strip.split(/\s*,\s*/))
    redirect "/poll/#{poll_id}"
  }
end
