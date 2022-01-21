require 'duration'

RSpec.describe(Main, type: :rack_test) {
  context('get /') {
    it('renders logged out page when there is no email cookie') {
      expect_slim(:logged_out, req: an_instance_of(Tony::Request))
      get '/'
      expect(last_response.ok?).to(be(true))
    }

    it('renders logged in page when there is an email cookie') {
      # Create poll and group data.
      user = create_user
      Array.new(3).fill { create_group(email: user.email) }
      upcoming_polls = Array.new(22).fill { |i|
        create_poll(email: user.email,
                    group_id: user.groups.sample.id,
                    expiration: future + (i + 1).minutes)
      }
      past_polls = Array.new(22).fill { |i|
        create_poll(email: user.email,
                    group_id: user.groups.sample.id,
                    expiration: future - (i + 1).minutes)
      }
      freeze_time(future)

      # Test that we limit only see 20
      upcoming_polls = upcoming_polls.first(20)
      past_polls = past_polls.first(20)

      set_cookie(:email, user.email)
      expect_slim(:logged_in, email: user.email,
                              groups: user.groups,
                              upcoming_polls: upcoming_polls,
                              past_polls: past_polls)
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
      expect_slim(:logged_out, req: an_instance_of(Tony::Request))
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

    it('defaults to / when there is no :r in state') {
      auth_google(Tony::Auth::LoginInfo.new(email: email, state: {}))
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/'))
    }
  }
}
