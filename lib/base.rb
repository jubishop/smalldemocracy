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
    get('/throw_error', ->(req, resp) {
      if on_prod?(req)
        resp.redirect('/')
        return
      end

      raise(ZeroDivisionError, 'Fuck you')
    })
  end

  private

  def on_prod?(req)
    return req.host_authority == 'www.smalldemocracy.com'
  end

  def list_param(req, key, default = nil)
    items = param(req, key, default)

    unless items.is_a?(Enumerable)
      throw(:response, [400, "Invalid #{key} given"])
    end
    items = items.compact.delete_if { |item| item.to_s.empty? }
    return items if items == default

    throw(:response, [400, "No #{key} given"]) if items.empty?

    return items
  end

  def param(req, key, default = nil)
    if req.params[key].nil? || req.params[key].to_s.empty?
      return default unless default.nil?

      throw(:response, [400, "No #{key} given"])
    end

    return req.params.fetch(key)
  end
end
