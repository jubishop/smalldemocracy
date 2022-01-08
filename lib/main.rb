require_relative 'base'
require_relative 'models/user'

class Main < Base
  def initialize
    super(Tony::Slim.new(views: 'views',
                         layout: 'views/layout',
                         options: {
                           include_dirs: [
                             File.join(Dir.pwd, 'views/partials')
                           ]
                         }))

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
      login_info = req.env['login_info']
      resp.set_cookie(:email, login_info.email)
      resp.redirect(login_info.state&.fetch(:r, '/') || '/')
    })
  end
end
