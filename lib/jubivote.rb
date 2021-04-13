require 'sequel'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

module JubiVote
  DB = Sequel.sqlite(ENV.fetch('JUBIVOTE_DATABASE_FILE'))
  public_constant :DB

  Sequel.extension(:migration)
  Sequel::Migrator.check_current(DB, 'db/migrations')
end

require_relative 'admin'

module JubiVote
  class App < Sinatra::Base
    helpers Sinatra::ContentFor
    register Sinatra::Static

    set(public_folder: 'public')
    set(views: 'views')

    get('/') {
      erb :index
      puts DB[:polls].count
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
end
