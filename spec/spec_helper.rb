require 'capybara/apparition'
require 'capybara/rspec'
require 'rack'
require 'rack/test'
require 'tony/test'

ENV['APP_ENV'] = 'test'
ENV['RACK_ENV'] = 'test'
ENV['JUBIVOTE_COOKIE_SECRET'] = 'U3v96K59yMnjmnb97CeSNDp4'
ENV['JUBIVOTE_HASHED_PASSWORD'] = 'MMlS+rEiw/l1nwKm2Vw3WLJGtP7iOZV7LU/uRuJhcMQ='
ENV['JUBIVOTE_CIPHER_KEY'] = 'gYUHA6sIrfFQaFePp0Srt3JVTnCHJBKT'
ENV['SENDGRID_API_KEY'] = 'dummy_api_key'

require_relative '../setup'

require_relative 'helpers/env'
require_relative 'helpers/goldens'
require_relative 'helpers/models'

Capybara.server = :puma
Capybara.app = Rack::Builder.parse_file('config.ru').first
Capybara.default_max_wait_time = 5

Capybara.register_driver(:apparition) { |app|
  Capybara::Apparition::Driver.new(app, {
    headless: !ENV.fetch('CHROME_DEBUG', false)
  })
}
Capybara.default_driver = :apparition

RSpec.shared_context(:apparition) do
  include Capybara::RSpecMatchers
  include Tony::Test::Apparition::Cookies

  let(:cookie_secret) { ENV.fetch('JUBIVOTE_CIPHER_KEY') }

  before(:each) {
    page.driver.headers = { Origin: 'http://localhost' }
  }

  after(:each) {
    clear_cookies
    Capybara.reset_sessions!
  }
end

RSpec.shared_context(:rack_test) do
  include Capybara::RSpecMatchers
  include Rack::Test::Methods
  include Tony::Test::Rack::Cookies

  let(:app) { Capybara.app }
  let(:cookie_secret) { ENV.fetch('JUBIVOTE_CIPHER_KEY') }

  after(:each) {
    clear_cookies
  }
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.default_formatter = 'doc'
  config.alias_it_should_behave_like_to(:it_has_behavior, 'has behavior:')

  config.order = :random
  Kernel.srand(config.seed)

  config.include(RSpec::Models)
  config.include_context(:apparition, type: :feature)
  config.include_context(:rack_test, type: :rack_test)

  config.after(:each) {
    ENV['APP_ENV'] = 'test'
    ENV['RACK_ENV'] = 'test'
  }
end
