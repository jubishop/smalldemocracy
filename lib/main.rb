require_relative 'base'

class Main < Base
  def initialize
    super

    get('/', ->(req, resp) {
      resp.write(slim.render(:index, email: fetch_email(req)))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email_address)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    not_found(->(_, resp) {
      resp.write(slim.render(:not_found))
    })
  end
end
