require 'base64'
require 'openssl'
require 'rack/ssl-enforcer'

require_relative 'lib/rack/admin_auth'
require_relative 'lib/jubivote'

use Rack::SslEnforcer unless ENV.fetch('RACK_ENV') == 'development'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

use(AdminOnlyAuth) { |_, password|
  Rack::Utils.secure_compare(
      Base64.strict_encode64(OpenSSL::Digest.new('SHA256').digest(password)),
      ENV.fetch('JUBIVOTE_HASHED_PASSWORD'))g
}

run JubiVote
