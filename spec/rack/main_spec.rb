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

    it('does not delete the email cookie') {
      set_cookie(:email, 'nom@nom')
      get '/'
      expect(get_cookie(:email)).to(eq('nom@nom'))
    }
  }

  context('in faux production') {
    def get_path(path)
      # rubocop:disable Style/StringHashKeys
      get(path, {}, { 'HTTPS' => 'on' })
      # rubocop:enable Style/StringHashKeys
    end

    before(:all) {
      ENV['APP_ENV'] = 'production'
      ENV['RACK_ENV'] = 'production'
      Capybara.app = Rack::Builder.parse_file('config.ru').first
    }

    before(:each) {
      ENV['APP_ENV'] = 'production'
      ENV['RACK_ENV'] = 'production'
    }

    it('renders logged out page when there is no email cookie') {
      expect_slim(:index, email: false, req: an_instance_of(Tony::Request))
      get_path('/')
    }

    it('renders logged in page when there is an email cookie') {
      set_cookie(:email, 'my@email')
      expect_slim(:index, email: 'my@email', req: an_instance_of(Tony::Request))
      get_path('/')
    }

    it('does not reveal error message stack traces in production') {
      expect_slim(:not_found)
      get_path('/throw_error')
    }

    after(:all) {
      ENV['APP_ENV'] = 'test'
      ENV['RACK_ENV'] = 'test'
      Capybara.app = Rack::Builder.parse_file('config.ru').first
    }
  }

  context('get /logout') {
    it('deletes the email cookie') {
      set_cookie(:email, 'nomnomnom')
      get '/logout'
      expect(get_cookie(:email)).to(be_nil)
    }

    it('redirects after logging out') {
      get '/logout?r=/somewhere_else'
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/somewhere_else'))
    }
  }

  context('get /auth/google') {
    before(:each) {
      @login_info = Tony::Auth::LoginInfo.new(email: 'jubi@github.com',
                                              state: { r: '/onward' })
    }

    it('sets the email address') {
      set_cookie(:email, 'nomnomnom')
      # rubocop:disable Style/StringHashKeys
      get '/auth/google', {}, { 'login_info' => @login_info }
      # rubocop:enable Style/StringHashKeys
      expect(get_cookie(:email)).to(eq('jubi@github.com'))
    }

    it('redirects to :r in state') {
      # rubocop:disable Style/StringHashKeys
      get '/auth/google', {}, { 'login_info' => @login_info }
      # rubocop:enable Style/StringHashKeys
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/onward'))
    }
  }

  it('renders not found to unknown urls') {
    expect_slim(:not_found)
    get '/not_a_url'
  }
}
