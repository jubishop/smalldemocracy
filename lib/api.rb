require_relative 'base'
require_relative 'models/user'

class API < Base
  include Helpers::Guard

  def initialize
    super

    get('/api', ->(req, resp) {
      email = fetch_email(req)

      if email
        user = Models::User.find_or_create(email: email)
        return 200, @slim.render(:api, user: user)
      end

      resp.redirect('/')
    })
  end
end
