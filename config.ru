require 'rack/contrib'
require 'rack/protection'
require 'tony'
require 'tony/auth'

require_relative 'setup'

use Honeybadger::Rack::ErrorNotifier if ENV.fetch('RACK_ENV') == 'production'
use Tony::SSLEnforcer if ENV.fetch('RACK_ENV') == 'production'
use Rack::Session::Cookie, secret: ENV.fetch('SMALLDEMOCRACY_COOKIE_SECRET')
use Rack::Protection if ENV.fetch('RACK_ENV') == 'production'
use Rack::JSONBodyParser
use Tony::Auth::Google, client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
                        secret: ENV.fetch('GOOGLE_SECRET')
use Tony::Auth::Github, client_id: ENV.fetch('GITHUB_CLIENT_ID'),
                        secret: ENV.fetch('GITHUB_SECRET')
use Tony::Auth::Facebook, client_id: ENV.fetch('FACEBOOK_CLIENT_ID'),
                          secret: ENV.fetch('FACEBOOK_SECRET')

use Tony::Static
run Rack::URLMap.new(Setup.url_map)
