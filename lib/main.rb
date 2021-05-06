require 'tony'

class Main < Tony::App
  def initialize
    super(secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET'))
    slim = Tony::Slim.new(views: 'views', layout: 'views/layout')

    get('/', ->(req, resp) {
      resp.write(slim.render(:index, email: fetch_email(req)))
    })

    get('/logout', ->(req, resp) {
      resp.delete_cookie(:email)
      resp.redirect(req.params.fetch(:r, '/'))
    })

    not_found(->(_, resp) {
      resp.write(slim.render(:not_found))
    })
  end

  def fetch_email(req)
    email = req.get_cookie(:email)
    return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
  end
end
