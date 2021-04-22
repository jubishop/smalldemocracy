require_relative '../../lib/helpers/cookie'
require_relative '../../lib/utils/crypt'

module RSpec
  module RackSession
    def set_email_cookie(email: 'test@example.com')
      rack_mock_session.cookie_jar[:email] = Utils::Crypt.en(email)
      return email
    end
  end

  module ApparitionSession
    def set_email_cookie(page:, email: 'test@example.com')
      page.driver.set_cookie(:email, Utils::Crypt.en(email))
      return email
    end
  end
end
