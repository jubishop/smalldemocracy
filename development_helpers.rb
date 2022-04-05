# rubocop:disable Style/TopLevelMethodDefinition

def connect_sequel_db
  require 'sequel/core'

  case ENV.fetch('APP_ENV')
  when 'production'
    return Sequel.postgres(ENV.fetch('DATABASE_URL'))
  when 'development'
    return Sequel.postgres(database: 'smalldemocracy_dev')
  end
end

def stub_environment_vars(environment)
  ENV['APP_ENV'] ||= environment
  ENV['RACK_ENV'] ||= environment
  ENV['SMALLDEMOCRACY_HASHED_PASSWORD'] ||= # smalldemocracy
    'NSEP7WaLUZYPopbrOvl4sokJ5eUVr6iae+qpr78vYyA='
  ENV['SMALLDEMOCRACY_COOKIE_SECRET'] ||= 'gYUHA6sIrfFQaFePp0Srt3JVTnCHJBKT'
  ENV['POLL_ID_SALT'] ||= 'pollsalt'
  ENV['GROUP_ID_SALT'] ||= 'groupsalt'
  ENV['GITHUB_CLIENT_ID'] ||= 'clientid'
  ENV['GITHUB_SECRET'] ||= 'secret'
  ENV['GOOGLE_CLIENT_ID'] ||= 'clientid'
  ENV['GOOGLE_SECRET'] ||= 'secret'
  ENV['FACEBOOK_CLIENT_ID'] ||= 'clientid'
  ENV['FACEBOOK_SECRET'] ||= 'secret'
end

# rubocop:enable Style/TopLevelMethodDefinition
