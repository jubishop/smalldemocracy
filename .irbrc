require 'sequel'
DB = Sequel.postgres(database: 'smalldemocracy_dev')

require_relative 'lib/models/choice'
require_relative 'lib/models/group'
require_relative 'lib/models/member'
require_relative 'lib/models/poll'
require_relative 'lib/models/response'
require_relative 'lib/models/user'
require_relative 'spec/helpers/models'

class Object
  include RSpec::Models
end

ENV['APP_ENV'] = 'test'
