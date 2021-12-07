require 'tony'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'

class Base < Tony::App
  include Helpers::Cookie
  include Helpers::Guard

  def initialize(slim = Tony::Slim.new(views: 'views', layout: 'views/layout'))
    super(secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET'))
    @slim = slim

    not_found(->(_, resp) {
      resp.write(@slim.render(:not_found))
    })

    error(->(_, resp) {
      raise resp.error unless ENV['APP_ENV'] == 'production'

      resp.status = 500
      resp.write('Sorry, an error has occurred')
    })
  end
end
