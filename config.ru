require 'rack/contrib'
require 'rack/ssl-enforcer'
require 'tony'

require_relative 'setup'

use Rack::SslEnforcer, only_environments: 'production'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection if ENV.fetch('RACK_ENV') == 'production'
use Rack::JSONBodyParser

use Tony::Static
run Rack::URLMap.new(Setup.url_map)
