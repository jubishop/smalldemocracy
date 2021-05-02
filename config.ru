require 'rack/contrib'
require 'tony'

require_relative 'setup'

module Tony
  class SSLEnforcer
    def initialize(app, **options)
      @app = app
      @options = options
    end
    def call(env)
      req = Rack::Request.new(env)
      if req.scheme == 'http'
        
      return @app.call(env)
    end
  end
end

use Tony::SSLEnforcer
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection if ENV.fetch('RACK_ENV') == 'production'
use Rack::JSONBodyParser

use Tony::Static
run Rack::URLMap.new(Setup.url_map)
