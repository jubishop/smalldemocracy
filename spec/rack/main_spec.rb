RSpec.describe(Main, type: :rack_test) {
  context('get /') {
    it('renders logged out page when there is no email cookie') {
      expect_slim(:index, email: false, req: an_instance_of(Tony::Request))
      get '/'
      expect(last_response.ok?).to(be(true))
    }

    it('renders logged in page when there is an email cookie') {
      set_cookie(:email, 'my@email')
      expect_slim(:index, email: 'my@email', req: an_instance_of(Tony::Request))
      get '/'
    }

    it('does not delete any existing email cookie') {
      set_cookie(:email, 'nom@nom')
      get '/'
      expect(get_cookie(:email)).to(eq('nom@nom'))
    }
  }

  context('get /logout') {
    it('deletes the email cookie') {
      set_cookie(:email, 'nomnomnom')
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
    before(:each) {
      @login_info = Tony::Auth::LoginInfo.new(email: 'me@email',
                                              state: { r: '/onward' })
    }

    it('sets the email address') {
      set_cookie(:email, 'nomnomnom')
      # rubocop:disable Style/StringHashKeys
      get '/auth/google', {}, { 'login_info' => @login_info }
      # rubocop:enable Style/StringHashKeys
      expect(get_cookie(:email)).to(eq('me@email'))
    }

    it('redirects to :r in state') {
      # rubocop:disable Style/StringHashKeys
      get '/auth/google', {}, { 'login_info' => @login_info }
      # rubocop:enable Style/StringHashKeys
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/onward'))
    }
  }
}
