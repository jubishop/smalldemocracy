require 'rack/ssl-enforcer'

require_relative 'lib/jubivote'

use Rack::SslEnforcer unless Socket.gethostname.end_with?('local')
use Rack::Session::Cookie, secret: ENV.fetch('JUBIGEM_COOKIE_SECRET')
use Rack::Protection

run JubiVote::App
