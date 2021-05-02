require 'rack/contrib'
require 'tony'

require_relative 'setup'

if ENV.fetch('RACK_ENV') == 'production'
  use Tony::SSLEnforcer
  use Rack::Protection
end

use Tony::Static
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::JSONBodyParser

run Rack::URLMap.new(Setup.url_map)
