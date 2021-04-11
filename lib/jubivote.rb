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

    post '/auth/:provider/callback' do
      content_type 'text/plain'
      begin
        request.env['omniauth.auth'].to_hash.inspect
      rescue StandardError
        'No Data'
      end
    end

    get '/auth/:provider/callback' do
      content_type 'text/plain'
      begin
        request.env['omniauth.auth'].to_hash.inspect
      rescue StandardError
        'No Data'
      end
    end

    get '/auth/failure' do
      content_type 'text/plain'
      begin
        request.env['omniauth.auth'].to_hash.inspect
      rescue StandardError
        'No Data'
      end
    end
  end
end
