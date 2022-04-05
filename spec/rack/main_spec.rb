require 'duration'

require_relative 'shared_examples/auth_flow'

RSpec.describe(Main, type: :rack_test) {
  context('get /') {
    it('renders logged out page when there is no email cookie') {
      clear_cookies
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
      get '/'
      expect(get_cookie(:email)).to(eq(email))
    }
  }

  context('get /logout') {
    it('deletes the email cookie') {
      expect(get_cookie(:email)).to_not(be_nil)
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
    let(:path) { '/auth/google' }
    it_has_behavior('auth flow')
  }

  context('get /auth/github') {
    let(:path) { '/auth/github' }
    it_has_behavior('auth flow')
  }

  context('get /auth/facebook') {
    let(:path) { '/auth/facebook' }
    it_has_behavior('auth flow')
  }

  context('post /fake_login') {
    before(:each) {
      clear_cookies
    }

    it('rejects logging in when in production') {
      ENV['APP_ENV'] = 'production'
      post 'fake_login', email: email
      expect(get_cookie(:email)).to(be_empty)
    }

    it('logs in when in development') {
      expect(get_cookie(:email)).to(be_empty)
      ENV['APP_ENV'] = 'development'
      post 'fake_login', email: email
      expect(get_cookie(:email)).to(eq(email))
    }
  }
}
