require 'base64'
require 'linguistics'
require 'openssl'
require 'rack/ssl-enforcer'
require 'sequel'
require 'slim'
require 'slim/include'

Linguistics.use(:en)

Slim::Engine.set_options(
    tabsize: 2,
    include_dirs: ["#{Dir.pwd}/views/partials"],
    pretty: ENV.fetch('APP_ENV') == 'development')

DB = Sequel.sqlite('.data/db.sqlite')
Sequel.extension(:migration)
Sequel::Migrator.check_current(DB, 'db/migrations')

require_relative 'lib/admin'
require_relative 'lib/jubivote'

use Rack::SslEnforcer unless ENV.fetch('RACK_ENV') == 'development'
use Rack::Session::Cookie, secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET')
use Rack::Protection

# rubocop:disable Style/StringHashKeys
run Rack::URLMap.new({
  '/' => JubiVote,
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
