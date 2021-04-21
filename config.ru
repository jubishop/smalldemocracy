require 'base64'
require 'openssl'
require 'rack/ssl-enforcer'

require_relative 'setup'

require_relative 'lib/admin'
require_relative 'lib/main'
require_relative 'lib/poll'

module Rack
  class SslEnforcer
    def current_scheme
      return @request.env['HTTP_FLY_FORWARDED_PROTO']
    end
  end
end
use Rack::SslEnforcer, only_environments: 'production'
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
