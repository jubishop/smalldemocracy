require 'base64'
require 'linguistics'
require 'openssl'
require 'sequel'
require 'slim'
require 'tony'
require 'honeybadger'  # Always last

Sequel.application_timezone = :utc
Sequel.database_timezone = :utc
Sequel.typecast_timezone = :utc
Sequel.extension(:migration)
DB = case ENV.fetch('APP_ENV')
     when 'production'
       Sequel.connect(ENV.fetch('DATABASE_URL'))
     when 'development'
       Sequel.postgres(database: 'smalldemocracy_dev')
     when 'test'
       if ENV.key?('CI') # Github Actions
         Sequel.postgres(database: 'smalldemocracy',
                         user: 'postgres',
                         host: 'localhost',
                         port: 5432)
       else # Local
         Sequel.postgres(database: 'smalldemocracy_test')
       end
     end
DB.extension(:pg_enum)
DB.extension(:pg_json)
if ENV.fetch('RESET_DB_ON_SETUP', false)
  Sequel::Migrator.run(DB, 'db/migrations', target: 0)
end
Sequel::Migrator.run(DB, 'db/migrations')

Linguistics.use(:en)

Slim::Engine.set_options(
    tabsize: 2,
    pretty: ENV.fetch('APP_ENV') != 'production')

require_relative 'lib/helpers/env'
Tony::Slim::Env.include(Helpers::Env)

require_relative 'lib/admin'
require_relative 'lib/api'
require_relative 'lib/group'
require_relative 'lib/main'
require_relative 'lib/poll'

module Setup
  def self.url_map
    # rubocop:disable Style/StringHashKeys
    return {
      '/' => Main.new,
      '/api' => API.new,
      '/group' => Group.new,
      '/poll' => Poll.new,
      '/admin' => Rack::Builder.app {
        use(Rack::Auth::Basic) { |_, pw|
          Rack::Utils.secure_compare(
              Base64.strict_encode64(OpenSSL::Digest.new('SHA256').digest(pw)),
              ENV.fetch('SMALLDEMOCRACY_HASHED_PASSWORD'))
        }
        run(Admin.new)
      }
    }
    # rubocop:enable Style/StringHashKeys
  end
end
