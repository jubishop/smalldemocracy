require_relative '../../lib/helpers/cookie'
require_relative '../../lib/utils/crypt'

module RSpec
  module Session
    def set_email_cookie(page: nil, email: 'test@example.com')
      encrypted_email = Utils::Crypt.en(email)
      if page
        page.driver.set_cookie(:email, encrypted_email)
      else
        rack_mock_session.cookie_jar[:email] = encrypted_email
      end
      return email
    end
  end
end
