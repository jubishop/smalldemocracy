require 'capybara/apparition'
require 'securerandom'
require 'tony/test'

ENV['APP_ENV'] = 'test'
ENV['RACK_ENV'] = 'test'
ENV['JUBIVOTE_HASHED_PASSWORD'] = 'MMlS+rEiw/l1nwKm2Vw3WLJGtP7iOZV7LU/uRuJhcMQ='
ENV['JUBIVOTE_COOKIE_SECRET'] = 'gYUHA6sIrfFQaFePp0Srt3JVTnCHJBKT'
ENV['SENDGRID_API_KEY'] = 'dummy_api_key'
ENV['GOOGLE_CLIENT_ID'] = 'id'
ENV['GOOGLE_SECRET'] = 'secret'

require_relative '../setup'

require_relative 'helpers/models'

Capybara.server = :puma
Capybara.app = Rack::Builder.parse_file('config.ru').first
Capybara.default_max_wait_time = 5
Capybara.disable_animation = true

Capybara.register_driver(:apparition) { |app|
  Capybara::Apparition::Driver.new(app, {
    headless: !ENV.fetch('CHROME_DEBUG', false)
  })
}
Capybara.default_driver = :apparition

RSpec.shared_context(:capybara) do
  include_context(:tony_capybara)

  let(:cookie_secret) { ENV.fetch('JUBIVOTE_COOKIE_SECRET') }

  def set_timezone
    expect(page).to(have_timezone)
    page.driver.set_cookie(:tz, 'America/New_York')
  end

  def refresh_page
    set_timezone
    refresh
  end
end

RSpec.shared_context(:rack_test) {
  include_context(:tony_rack_test)

  let(:app) { Capybara.app }
  let(:cookie_secret) { ENV.fetch('JUBIVOTE_COOKIE_SECRET') }
}

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

  config.order = :random
  Kernel.srand(config.seed)

  config.include(RSpec::Models)
  config.include_context(:capybara, type: :feature)
  config.include_context(:rack_test, type: :rack_test)

  config.before(:each) {
    allow(Tony::Auth::Google).to(receive(:url)).and_return(
        SecureRandom.alphanumeric(24))
  }

  config.after(:each) {
    ENV['APP_ENV'] = 'test'
    ENV['RACK_ENV'] = 'test'
  }
end
