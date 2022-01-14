require 'honeybadger'
require 'tony'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'

class Base < Tony::App
  include Helpers::Cookie
  include Helpers::Guard

  def initialize(slim = Tony::Slim.new(views: 'views',
                                       partials: 'views/partials',
                                       layout: 'views/layout'))
    super(secret: ENV.fetch('SMALLDEMOCRACY_COOKIE_SECRET'))
    @slim = slim

    not_found(->(_, _) {
      return 404, @slim.render(:not_found)
    })

    error(->(req, resp) {
      raise resp.error unless ENV.fetch('APP_ENV') == 'production'

      puts resp.error.full_message(highlight: true, order: :top) if on_prod?
      Honeybadger.notify(resp.error)

      stack_trace = nil
      if session_is_privileged?(req)
        stack_trace = Rack::ShowExceptions.new(self).pretty(req.env, resp.error)
      end
      return 500, @slim.render(:error, stack_trace: stack_trace)
    })

    # For testing only
    get('/throw_error', ->(_, resp) {
      if on_prod?
        resp.redirect('/')
        return
      end

      raise(ZeroDivisionError, 'Fuck you')
    })
  end

  private

  def on_prod?
    return ENV.fetch('ON_PROD', false)
  end
end
