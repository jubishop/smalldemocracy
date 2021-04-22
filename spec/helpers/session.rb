require_relative '../../lib/helpers/cookie'

module RSpec
  module Session
    def fake_email_cookie(email = 'test@example.com')
      allow_any_instance_of(Helpers::Cookie).to(
          receive(:fetch_email).and_return(email))
      return email
    end
  end
end
