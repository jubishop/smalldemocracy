require_relative '../../lib/helpers/cookie'
require_relative '../../lib/utils/crypt'

module Capybara
  class Session
    def email_cookie=(email)
      driver.set_cookie(:email, Utils::Crypt.en(email))
    end
  end
end

module RSpec
  module RackSession
    def email_cookie=(email)
      rack_mock_session.cookie_jar[:email] = Utils::Crypt.en(email)
    end
  end
end
