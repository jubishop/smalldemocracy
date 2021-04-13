require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

DB = Sequel.sqlite(ENV.fetch('JUBIVOTE_DATABASE_FILE'))
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'admin'

class JubiVote < Sinatra::Base
  helpers Sinatra::ContentFor
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')

  get('/') {
    puts DB[:polls].count
    erb :index
  }

  get('/admin') {
    erb :admin
  }

  get('/admin/create_poll') {
    erb :create_poll
  }

  post('/admin/create_poll') {
    Admin.create_poll('test title')
    return 'poll created'
  }
end
