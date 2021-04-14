require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

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
    erb :index
  }

  get('/poll/:poll_id') {
    erb :poll, locals: { poll: Poll[params[:poll_id]] }
  }

  #####################################
  # ADMIN
  #####################################
  get('/admin') {
    erb :admin
  }

  get('/admin/create_poll') {
    erb :create_poll
  }

  post('/admin/create_poll') {
    poll_id = Admin.create_poll(
        title: params[:title],
        choices: params[:choices].strip.split(/\s*,\s*/))
    redirect "/poll/#{poll_id}"
  }
end
