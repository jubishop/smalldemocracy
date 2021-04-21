require 'base64'
require 'openssl'
require 'rack/ssl-enforcer'

require_relative 'setup'

require_relative 'lib/admin'
require_relative 'lib/main'
require_relative 'lib/poll'

if ENV.fetch('RACK_ENV') == 'production'
  class HTTPSRedirect
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.ssl?
        @app.call(env)
      else
        location = URI(req.url)
        location.scheme = 'https'
        [
          301, # permanent redirect
          {
            Location: location.to_s,
            'Content-Type': 'text/html',
            'Content-Length': '0'
          },
          [] # body
        ]
      end
    end
  end
  use HTTPSRedirect
end

use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

# rubocop:disable Style/StringHashKeys
run Rack::URLMap.new({
  '/' => Main,
  '/poll' => Poll,
  '/admin' => Rack::Builder.app {
    use(Rack::Auth::Basic) { |_, pw|
      Rack::Utils.secure_compare(
          Base64.strict_encode64(OpenSSL::Digest.new('SHA256').digest(pw)),
          ENV.fetch('JUBIVOTE_HASHED_PASSWORD'))
    }
    run(Admin)
  }
})
# rubocop:enable Style/StringHashKeys
