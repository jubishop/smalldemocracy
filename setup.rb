require 'base64'
require 'linguistics'
require 'openssl'
require 'sequel'
require 'slim'
require 'slim/include'

Linguistics.use(:en)

Slim::Engine.set_options(
    tabsize: 2,
    pretty: ENV.fetch('APP_ENV') != 'production')

DB = case ENV.fetch('APP_ENV')
     when 'development'
       Sequel.postgres(database: 'smalldemocracy_dev',
                       user: 'jubishop',
                       host: 'localhost',
                       port: 5432)
     when 'production'
       Sequel.postgres(ENV.fetch('DATABASE_URL'))
     when 'test'
       if ENV.key?('CI') # Remote CI
         Sequel.postgres(database: 'smalldemocracy',
                         user: 'postgres',
                         host: 'localhost',
                         port: 5432)
       else
         Sequel.postgres # Local
       end
     end

DB.extension(:pg_enum)
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
      '/poll' => Poll.new,
      '/admin' => Rack::Builder.app {
        use(Rack::Auth::Basic) { |_, pw|
          Rack::Utils.secure_compare(
              Base64.strict_encode64(OpenSSL::Digest.new('SHA256').digest(pw)),
              ENV.fetch('JUBIVOTE_HASHED_PASSWORD'))
        }
        run(Admin.new)
      }
    }
    # rubocop:enable Style/StringHashKeys
  end
end
