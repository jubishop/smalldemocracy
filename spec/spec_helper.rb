require 'capybara/apparition'
require 'capybara/rspec'
require 'colorize'
require 'rack'
require 'rack/test'

require_relative 'helpers/env'
require_relative 'helpers/goldens'
require_relative 'helpers/matchers'
require_relative 'helpers/cookies'

# Basic ENV vars
ENV['RACK_ENV'] = 'test'
ENV['APP_ENV'] = 'test'
ENV['JUBIVOTE_COOKIE_SECRET'] = 'U3v96K59yMnjmnb97CeSNDp4'
ENV['JUBIVOTE_HASHED_PASSWORD'] = 'MMlS+rEiw/l1nwKm2Vw3WLJGtP7iOZV7LU/uRuJhcMQ='
ENV['JUBIVOTE_CIPHER_IV'] = 'qqwmQKGBbRo6wOLX'
ENV['JUBIVOTE_CIPHER_KEY'] = 'gYUHA6sIrfFQaFePp0Srt3JVTnCHJBKT'

Capybara.server = :puma
Capybara.app = Rack::Builder.parse_file('config.ru').first
Capybara.default_max_wait_time = 5

Capybara.register_driver(:apparition) { |app|
  Capybara::Apparition::Driver.new(app, {
    headless: !ENV.fetch('CHROME_DEBUG', false),
    headers: { Origin: 'http://localhost' }
  })
}
Capybara.default_driver = :apparition

RSpec.shared_context(:apparition) do
  include Capybara::RSpecMatchers

  before(:each) {
    page.driver.headers = { Origin: 'http://localhost' }
  }

  after(:each) {
    page.clear_cookies
    Capybara.reset_sessions!
  }
end

RSpec.shared_context(:rack_test) do
  include Capybara::RSpecMatchers
  include Rack::Test::Methods
  include RSpec::RackCookies

  let(:app) { Capybara.app }

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
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.alias_it_should_behave_like_to(:it_has_behavior, 'has behavior:')

  config.order = :random
  Kernel.srand(config.seed)

  config.include_context(:apparition, type: :feature)
  config.include_context(:rack_test, type: :rack_test)

  require_relative '../setup'
  config.before(:each) {
    ENV['RACK_ENV'] = 'test'
    ENV['APP_ENV'] = 'test'
  }
end
