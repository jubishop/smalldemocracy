require_relative '../helpers/main/expectations'

RSpec.describe(Main, type: :rack_test) {
  include RSpec::MainExpectations

  context('get /') {
    it('displays logged out page when there is no email cookie') {
      get '/'
      expect_logged_out_index_page
    }

    it('displays logged in page when there is an email cookie') {
      set_cookie(:email_address, 'test@example.com')
      get '/'
      expect_logged_in_index_page('test@example.com')
    }

    it('does not delete the email cookie') {
      set_cookie(:email_address, 'nomnomnom')
      get '/'
      expect(get_cookie(:email_address)).to(eq('nomnomnom'))
    }
  }

  context('in faux production') {
    before(:all) {
      ENV['APP_ENV'] = 'production'
      ENV['RACK_ENV'] = 'production'
      Capybara.app = Rack::Builder.parse_file('config.ru').first
    }

    it('displays logged out page when there is no email cookie') {
      # rubocop:disable Style/StringHashKeys
      get '/', {}, { 'HTTPS' => 'on' }
      # rubocop:enable Style/StringHashKeys
      expect_logged_out_index_page
    }

    it('displays logged in page when there is an email cookie') {
      set_cookie(:email_address, 'test@example.com')
      # rubocop:disable Style/StringHashKeys
      get '/', {}, { 'HTTPS' => 'on' }
      # rubocop:enable Style/StringHashKeys
      expect_logged_in_index_page('test@example.com')
    }

    after(:all) {
      Capybara.app = Rack::Builder.parse_file('config.ru').first
    }
  }

  context('get /logout') {
    it('deletes the email cookie') {
      set_cookie(:email_address, 'nomnomnom')
      # rubocop:disable Style/StringHashKeys
      get '/logout', {}, { 'HTTPS' => 'on' }
      # rubocop:enable Style/StringHashKeys
      expect(get_cookie(:email_address)).to(be_nil)
    }

    it('redirects after logging out') {
      get '/logout?r=/somewhere_else'
      expect(last_response.redirect?).to(be(true))
      expect(last_response.location).to(eq('/somewhere_else'))
    }
  }

  it('returns not found to unknown urls') {
    get '/not_a_url'
    expect_not_found_page
  }
}
