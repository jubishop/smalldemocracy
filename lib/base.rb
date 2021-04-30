require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/static'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'
require_relative 'helpers/slim'

class Base < Sinatra::Base
  include Helpers::Cookie
  include Helpers::Guard
  include Helpers::Slim

  helpers Sinatra::ContentFor
  helpers Sinatra::Cookies
  register Sinatra::Static

  set(public_folder: 'public')
  set(static: false)
  set(views: 'views')
  set(:cookie_options, expires: Time.at(2**31 - 1), path: '/')

  configure(:development) {
    enable :logging
  }

  error(Sinatra::NotFound) {
    slim :not_found
  }
end
