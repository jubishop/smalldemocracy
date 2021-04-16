require 'rack/ssl-enforcer'

require_relative 'lib/rack/admin_auth'
require_relative 'lib/jubivote'

use Rack::SslEnforcer unless ENV.fetch('RACK_ENV') == 'development'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

use(AdminOnlyAuth, 'jubivote', ENV.fetch('JUBIVOTE_MD5_SALT')) {
  ENV.fetch('JUBIVOTE_PASSWORD')
}

run JubiVote
