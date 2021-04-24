require_relative '../../lib/utils/crypt'

module Capybara
  class Session
    def set_cookie(name, value)
      driver.set_cookie(name, Utils::Crypt.en(value))
    end

    def get_cookie(name)
      return Utils::Crypt.de(driver.cookies[name.to_s].value)
    end

    def delete_cookie(name)
      driver.remove_cookie(name)
    end

    def clear_cookies
      driver.clear_cookies
    end
  end
end

module RSpec
  module RackCookies
    def set_cookie(name, value)
      rack_mock_session.cookie_jar[name] = Utils::Crypt.en(value)
    end

    def get_cookie(name)
      return Utils::Crypt.de(rack_mock_session.cookie_jar[name])
    end
  end
end
