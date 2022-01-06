require_relative 'email'

module Helpers
  module Cookie
    include Email

    def fetch_email(req)
      email = req.get_cookie(:email)
      return invalid_email(email: email, name: 'Cookie') ? false : email
    end
  end
end
