require 'tony'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'

class Base < Tony::App
  include Helpers::Cookie
  include Helpers::Guard

  def initialize(slim = Tony::Slim.new(views: 'views', layout: 'views/layout'))
    super(secret: ENV.fetch('SMALLDEMOCRACY_COOKIE_SECRET'))
    @slim = slim

    not_found(->(_, resp) {
      resp.write(@slim.render(:not_found))
    })

    error(->(_, resp) {
      raise resp.error unless ENV['APP_ENV'] == 'production'

      resp.write(@slim.render(:not_found))
    })

    # For testing only
    get('/throw_error', ->(req, resp) {
      resp.redirect('/') if on_prod?(req)
      raise(RuntimeError, 'Fuck you') # rubocop:disable Style/RedundantException
    })
  end

  def on_prod?(req)
    puts req.host_authority
    return req.host_authority == 'smalldemocracy.com'
  end
end
