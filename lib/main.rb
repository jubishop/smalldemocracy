require_relative 'base'

class Main < Base
  def initialize
    super
    @slim = Tony::Slim.new(views: 'views', layout: 'views/layout')

    get('/', ->(req, resp) {
      resp.write(@slim.render(:index, email: fetch_email(req), req: req))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email_address)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    not_found(->(_, resp) {
      resp.write(@slim.render(:not_found))
    })

    get('/auth/google', ->(req, resp) {
      login_info = req.env['login_info']
      resp.set_cookie(:email_address, login_info.email)
      resp.redirect(login_info.state[:redirect])
    })
  end
end
