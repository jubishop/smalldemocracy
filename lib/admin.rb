require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Admin < Base
  def initialize
    super

    get('/admin', ->(_, resp) {
      resp.write(@slim.render('admin/admin'))
    })
  end
end
