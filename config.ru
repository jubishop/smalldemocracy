require 'omniauth'
require 'omniauth-google-oauth2'
require 'rack/ssl-enforcer'

require_relative 'lib/jubivote'

use Rack::SslEnforcer unless Socket.gethostname.end_with?('local')
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

use(OmniAuth::Builder) {
  provider :google_oauth2,
           ENV.fetch('JUBIVOTE_GOOGLE_CLIENT_ID'),
           ENV.fetch('JUBIVOTE_GOOGLE_CLIENT_SECRET'),
           access_type: 'offline',
           prompt: 'consent',
           scope: 'email'
}

run JubiVote::App
