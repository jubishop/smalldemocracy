require 'rack/ssl-enforcer'

require_relative 'setup'

module Rack
  class SslEnforcer
    undef_method :current_scheme
    def current_scheme
      return @request.env.fetch('HTTP_FLY_FORWARDED_PROTO', 'http')
    end
  end
end
use Rack::SslEnforcer, only_environments: 'production'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection unless ENV.fetch('RACK_ENV') == 'test'

module Rack
  class LongCache
    def initialize(app)
      @app = app
      @file_server = Rack::File.new(::File.join(Dir.pwd, PUBLIC_FOLDER))
    end

    def call(env)
      req = Rack::Request.new(env)
      return @app.call(env) unless req.get?

      status, headers, body = @file_server.call(env)
      return @app.call(env) if status == 404

      headers['Cache-Control'] = 'public, max-age=31536000, immutable'
      return [status, headers, body]
    end
  end
end
use Rack::LongCache

run Rack::URLMap.new(Setup.url_map)
