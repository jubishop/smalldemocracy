require 'rack/test'

require_relative '../setup'
require_relative '../lib/main'

RSpec.describe(Main) {
  include Rack::Test::Methods

  let(:app) { Main }

  context('/') {
    it('responds to / with OK status') {
      get '/'
      expect(last_response.ok?).to(be(true))
    }

    it('does not delete the email cookie') {
      set_cookie('email=nomnomnom')
      get '/'
      expect(rack_mock_session.cookie_jar['email']).to(eq('nomnomnom'))
    }

    it('welcomes user when they have email cookie') {
      email = 'jubi@hey.com'
      require_relative '../lib/helpers/cookie'
      allow_any_instance_of(Helpers::Cookie).to(
          receive(:fetch_email).and_return(email))
      get '/'
      expect(last_response.body).to(include(email))
    }
  }

  context('/logout') {
    it('deletes the email cookie') {
      set_cookie('email=nomnomnom')
      get '/logout'
      expect(rack_mock_session.cookie_jar['email']).to(eq(''))
    }
  }
}
