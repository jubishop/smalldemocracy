RSpec.describe(Base, type: :rack_test) {
  context(:production) {
    before(:each) {
      ENV['APP_ENV'] = 'production'
      ENV['RACK_ENV'] = 'production'
    }

    it('does not print raw stack traces in production for normal users') {
      expect_slim(:error, stack_trace: nil)
      get '/throw_error'
      expect(last_response.status).to(be(500))
      expect(last_response.body).to_not(include('Fuck you'))
    }

    it('does not print raw stack traces in production for privileged users') {
      set_cookie(:email, 'jubishop@gmail.com')
      expect_slim(:error, stack_trace: an_instance_of(String))
      get '/throw_error'
      expect(last_response.status).to(be(500))
      expect(last_response.body).to(include('Fuck you'))
    }
  }

  it('renders not found to unknown urls') {
    expect_slim(:not_found)
    get '/not_a_url'
    expect(last_response.status).to(be(404))
  }
}
