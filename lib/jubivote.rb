require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

module JubiVote
  class App < Sinatra::Base
    helpers Sinatra::ContentFor
    register Sinatra::Static

    set(public_folder: 'public')
    set(views: 'views')

    get('/') {
      erb :index
    }

    get('/admin') {
      erb :admin
    }

    get('/admin/create_poll') {
      erb :create_poll
    }

    post('/admin/create_poll') {
      puts 'posting creation of poll'
    }
  end
end
