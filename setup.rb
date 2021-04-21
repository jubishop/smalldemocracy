require 'linguistics'
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
if ENV.fetch('APP_ENV') == 'test'
  Sequel::Migrator.run(DB, 'db/migrations')
else
  Sequel::Migrator.check_current(DB, 'db/migrations')
end
