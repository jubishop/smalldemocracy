require_relative 'base'

class Main < Base
  def initialize
    super

    get('/', ->(req, resp) {
      email = fetch_email(req)
      return 200, @slim.render(:logged_out, req: req) unless email

      resp.write(@slim.render(:logged_in, email: email))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    get('/auth/google', ->(req, resp) {
      login_info = req.env['login_info']
      resp.set_cookie(:email, login_info.email)
      resp.redirect(login_info.state&.fetch(:r, '/') || '/')
    })
  end
end
