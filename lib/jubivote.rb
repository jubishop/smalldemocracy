require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

module JubiVote
  class App < Sinatra::Base
    helpers Sinatra::ContentFor
    register Sinatra::Static

    get('/') {
      'hello world'
    }

    not_found {
      'This is nowhere to be found.'
    }
  end
end
