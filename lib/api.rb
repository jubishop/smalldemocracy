require_relative 'base'
require_relative 'models/user'

class API < Base
  include Helpers::Guard

  def initialize
    super

    get('/api', ->(_, _) {
      return 200, @slim.render(:api)
    })
  end
end
