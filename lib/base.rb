require 'tony'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'

class Base < Tony::App
  include Helpers::Cookie
  include Helpers::Guard

  def initialize(slim = Tony::Slim.new(views: 'views', layout: 'views/layout'))
    super(secret: ENV.fetch('SMALLDEMOCRACY_COOKIE_SECRET'))
    @slim = slim

    not_found(->(_, _) {
      return 404, @slim.render(:not_found)
    })

    error(->(_, resp) {
      raise resp.error unless ENV['APP_ENV'] == 'production'

      return 500, @slim.render(:error)
    })

    # For testing only
    get('/throw_error', ->(_, _) {
      raise(RuntimeError, 'Fuck you') # rubocop:disable Style/RedundantException
    })
  end
end
