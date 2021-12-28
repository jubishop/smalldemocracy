RSpec.describe(Base, type: :rack_test) {
  context('production') {
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

    it('does not reveal error message stack traces in production') {
      expect_slim(:error)
      get_path('/throw_error')
      expect(last_response.status).to(be(500))
    }

    after(:all) {
      ENV['APP_ENV'] = 'test'
      ENV['RACK_ENV'] = 'test'
      Capybara.app = Rack::Builder.parse_file('config.ru').first
    }
  }

  it('renders not found to unknown urls') {
    expect_slim(:not_found)
    get '/not_a_url'
    expect(last_response.status).to(be(404))
  }
}
