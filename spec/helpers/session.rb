require_relative '../../lib/helpers/cookie'
require_relative '../../lib/utils/crypt'

module Capybara
  class Session
    def set_cookie(key, value)
      driver.set_cookie(key, Utils::Crypt.en(value))
    end

    def get_cookie(key)
      return Utils::Crypt.de(driver.cookies[key.to_s].value)
    end
  end
end

module RSpec
  module RackSession
    def set_cookie(key, value)
      rack_mock_session.cookie_jar[key] = Utils::Crypt.en(value)
    end

    def get_cookie(key)
      return Utils::Crypt.de(rack_mock_session.cookie_jar[key])
    end
  end
end
