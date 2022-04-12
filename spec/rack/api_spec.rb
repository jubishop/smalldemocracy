RSpec.describe(API, type: :rack_test) {
  context('get /api') {
    it('shows api page') {
      user = Models::User.find_or_create(email: email)
      expect_slim(:api, user: user)
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
