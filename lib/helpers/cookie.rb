require_relative '../utils/crypt'

module Helpers
  module Cookie
    def fetch_email
      email = fetch_cookie(:email)
      return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
    end

    def store_cookie(key, value)
      cookies[key] = Utils::Crypt.en(value)
    end

    def fetch_cookie(key)
      return unless cookies.key?(key)

      return Utils::Crypt.de(cookies.fetch(key))
    end
  end
end
