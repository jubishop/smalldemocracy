require 'base64'
require 'linguistics'
require 'openssl'
require 'sequel'
require 'slim'
require 'slim/include'

Linguistics.use(:en)

Slim::Engine.set_options(
    tabsize: 2,
    include_dirs: ["#{Dir.pwd}/views/partials"],
    pretty: ENV.fetch('APP_ENV') != 'production')

DB = if ENV.fetch('APP_ENV') == 'test'
       Sequel.sqlite
     else
       Sequel.sqlite('.data/db.sqlite')
     end

Sequel.extension(:migration)
Sequel::Migrator.run(DB, 'db/migrations')

require_relative 'lib/admin'
require_relative 'lib/main'
require_relative 'lib/poll'

module Setup
  def self.url_map
    # rubocop:disable Style/StringHashKeys
    return {
      '/' => Main.new,
      '/poll' => Poll,
      '/admin' => Rack::Builder.app {
        use(Rack::Auth::Basic) { |_, pw|
          Rack::Utils.secure_compare(
              Base64.strict_encode64(OpenSSL::Digest.new('SHA256').digest(pw)),
              ENV.fetch('JUBIVOTE_HASHED_PASSWORD'))
        }
        run(Admin)
      }
    }
    # rubocop:enable Style/StringHashKeys
  end
end
