require 'tony'

module Helpers
  module Cookie
    def fetch_email(req)
      email = req.get_cookie(:email)
      return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
    end
  end
end
