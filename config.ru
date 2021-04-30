require 'rack/ssl-enforcer'
require 'tony'

require_relative 'setup'

module Rack
  class SslEnforcer
    undef_method :current_scheme
    def current_scheme
      return @request.env.fetch('HTTP_FLY_FORWARDED_PROTO', 'http')
    end
  end
end
use Rack::SslEnforcer, only_environments: 'production'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection unless ENV.fetch('RACK_ENV') == 'test'

use Tony::LongCache
run Rack::URLMap.new(Setup.url_map)
