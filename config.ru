require 'rack/ssl-enforcer'

require_relative 'lib/rack/admin_auth'
require_relative 'lib/jubivote'

use Rack::SslEnforcer unless Socket.gethostname.end_with?('local')
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

use(AdminOnlyAuth, 'jubivote') { |_, password|
  Rack::Utils.secure_compare(ENV.fetch('JUBIVOTE_PASSWORD'), password)
}

run JubiVote::App
