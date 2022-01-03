RSpec.describe(Main, type: :rack_test) {
  context('get /') {
    it('renders logged out page when there is no email cookie') {
      expect_slim(:index, email: false, req: an_instance_of(Tony::Request))
      get '/'
      expect(last_response.ok?).to(be(true))
    }

    it('renders logged in page when there is an email cookie') {
      set_cookie(:email, email)
      expect_slim(:index, email: email, req: an_instance_of(Tony::Request))
      get '/'
    }

    it('does not delete any existing email cookie') {
      set_cookie(:email, email)
      get '/'
      expect(get_cookie(:email)).to(eq(email))
    }
  }

  context('get /logout') {
    it('deletes the email cookie') {
      set_cookie(:email, email)
      get '/logout'
      expect(get_cookie(:email)).to(be_nil)
      expect(last_response.redirect?).to(be(true))
      expect_slim(:index, email: false, req: an_instance_of(Tony::Request))
      follow_redirect!
    }

    it('redirects to / by default') {
      get '/logout'
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/'))
    }

    it('redirects to ?r= when present') {
      get '/logout?r=/somewhere_else'
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/somewhere_else'))
    }
  }

  context('get /auth/google') {
    def auth_google(login_info)
      # rubocop:disable Style/StringHashKeys
      get('/auth/google', {}, { 'login_info' => login_info })
      # rubocop:enable Style/StringHashKeys
    end

    it('sets the email address') {
      set_cookie(:email, random_email)
      auth_google(Tony::Auth::LoginInfo.new(email: email))
      expect(get_cookie(:email)).to(eq(email))
    }

    it('redirects to / by default') {
      auth_google(Tony::Auth::LoginInfo.new(email: email))
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/'))
    }

    it('redirects to :r in state') {
      auth_google(Tony::Auth::LoginInfo.new(email: email,
                                            state: { r: '/onward' }))
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/onward'))
    }
  }
}
