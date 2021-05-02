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
      if req.scheme == 'http' || req.env['HTTP_X_FORWARDED_SSL'] == 'off'
        location = "https://#{req.host_with_port}#{req.fullpath}"
        body = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        return [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      end
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
