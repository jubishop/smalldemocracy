require 'tony'

module Capybara
  class Session
    @@crypt = Tony::Utils::Crypt.new(ENV.fetch('JUBIVOTE_CIPHER_KEY'))
    def set_cookie(name, value)
      driver.set_cookie(name, @@crypt.en(value))
    end

    def get_cookie(name)
      return @@crypt.de(driver.cookies[name.to_s].value)
    end

    def delete_cookie(name)
      driver.remove_cookie(name)
    end

    def clear_cookies
      driver.clear_cookies
    end
  end
end
