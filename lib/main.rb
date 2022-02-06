require_relative 'base'
require_relative 'models/user'

class Main < Base
  def initialize
    super

    get('/', ->(req, resp) {
      email = fetch_email(req)
      return 200, @slim.render(:logged_out, req: req) unless email

      user = Models::User.find_or_create(email: email)
      upcoming_polls = user.polls(start_expiration: Time.now, limit: 20)
      past_polls = user.polls(end_expiration: Time.now, limit: 20, order: :desc)
      resp.write(@slim.render(:logged_in, email: email,
                                          groups: user.groups,
                                          upcoming_polls: upcoming_polls,
                                          past_polls: past_polls))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    get('/auth/google', ->(req, resp) {
      login_info = req.env.fetch('login_info', nil)
      resp.set_cookie(:email, login_info.email) if login_info&.email
      resp.redirect(login_info&.state&.fetch(:r, '/') || '/')
    })

    get('/auth/github', ->(req, resp) {
      login_info = req.env.fetch('login_info', nil)
      resp.set_cookie(:email, login_info.email) if login_info&.email
      resp.redirect(login_info&.state&.fetch(:r, '/') || '/')
    })
  end
end
