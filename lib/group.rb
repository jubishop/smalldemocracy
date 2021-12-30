require_relative 'base'

class Group < Base
  def initialize
    super

    get('/group/create', ->(req, resp) {
      require_email(req)
      return 200, @slim.render('group/create')
    })
  end
end
