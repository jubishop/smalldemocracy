require 'tony'

module Helpers
  module Cookie
    @@crypt = Tony::Utils::Crypt.new(ENV.fetch('JUBIVOTE_COOKIE_SECRET'))

    def fetch_email
      email = fetch_cookie(:email)
      return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
    end

    def store_cookie(key, value)
      cookies[key] = @@crypt.en(value)
    end

    def fetch_cookie(key)
      return unless cookies.key?(key)

      return @@crypt.de(cookies.fetch(key))
    end
  end
end
