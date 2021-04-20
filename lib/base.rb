require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/static'

require_relative 'helpers'

class Base < Sinatra::Base
  include Helpers

  helpers Sinatra::ContentFor
  helpers Sinatra::Cookies
  register Sinatra::Static

  set(public_folder: 'public')
  set(views: 'views')
  set(:cookie_options, expires: Time.at(2**31 - 1))

  configure(:production, :development) {
    enable :logging
  }

  def method_missing(name, *args, &block)
    return super unless implemented?(name)

    return slim_template(folder: name.to_s.split('_').last,
                         template: args[0],
                         options: args[1])
  end

  def respond_to_missing?(name, include_private = false)
    implemented?(name) || super
  end

  private

  def slim_template(folder:, template:, options:)
    options ||= {}
    slim(template, **options.merge(views: "views/#{folder}",
                                   layout: :'../layout'))
  end

  def implemented?(name)
    return name.start_with?('slim_')
  end
end
