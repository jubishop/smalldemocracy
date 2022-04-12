RSpec.describe(API, type: :rack_test) {
  context('get /api') {
    it('shows api page') {
      expect_slim(:api, user: create_user(email: email))
      get '/api'
      expect(last_response.ok?).to(be(true))
    }

    it('redirects and asks for email with no cookie') {
      clear_cookies
      get '/api'
      expect(last_response.redirect?).to(be(true))
      expect_slim(:logged_out, req: an_instance_of(Tony::Request))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }
  }
}
