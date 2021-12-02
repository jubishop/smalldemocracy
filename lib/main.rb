require_relative 'base'

class Main < Base
  def initialize
    super

    get('/', ->(req, resp) {
      resp.write(@slim.render(:index, email: fetch_email(req), req: req))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    get('/auth/google', ->(req, resp) {
      login_info = req.env['login_info']
      resp.set_cookie(:email, login_info.email)
      resp.redirect(login_info.state[:r])
    })
  end
end
