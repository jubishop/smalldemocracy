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
  end
end
