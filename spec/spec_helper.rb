require 'capybara/apparition'
require 'capybara/rspec'
require 'rack'
require 'rack/test'

# Basic ENV vars
ENV['RACK_ENV'] = 'test'
ENV['APP_ENV'] = 'test'
ENV['JUBIVOTE_COOKIE_SECRET'] = 'U3v96K59yMnjmnb97CeSNDp4'
ENV['JUBIVOTE_HASHED_PASSWORD'] = 'MMlS+rEiw/l1nwKm2Vw3WLJGtP7iOZV7LU/uRuJhcMQ='
ENV['JUBIVOTE_CIPHER_IV'] = 'qqwmQKGBbRo6wOLX'
ENV['JUBIVOTE_CIPHER_KEY'] = 'gYUHA6sIrfFQaFePp0Srt3JVTnCHJBKT'

# Rack Testing Context
RSpec.shared_context(:rack_app) do
  include(Rack::Test::Methods)
  include(Capybara::RSpecMatchers)

  require_relative '../setup'
  full_stack_app = Rack::Builder.parse_file('config.ru').first

  let(:app) { full_stack_app }

  Capybara.server = :puma
  Capybara.app = full_stack_app
  Capybara.register_driver(:rack_test) { |app|
    Capybara::RackTest::Driver.new(app)
  }
  Capybara.register_driver(:apparition) { |app|
    Capybara::Apparition::Driver.new(app)
  }
  Capybara.default_max_wait_time = 5
  Capybara.default_driver = :rack_test
  Capybara.javascript_driver = :apparition

  before(:each) {
    ENV['RACK_ENV'] = 'test'
    ENV['APP_ENV'] = 'test'
  }

  after(:each) {
    Capybara.reset_sessions!
    Capybara.use_default_driver
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

  config.order = :random
  Kernel.srand(config.seed)

  config.include_context(:rack_app)
end

# Basic Helpers
def fake_email_cookie(email = 'test@example.com')
  require_relative '../lib/helpers/cookie'
  allow_any_instance_of(Helpers::Cookie).to(
      receive(:fetch_email).and_return(email))
  return email
end

def compare_golden(filename, **options)
  base64 = render_base64(**options)

  filepath = File.join('spec/goldens', filename)
  unless File.exist?(filepath)
    warn("Creating new golden: #{filename}")
    File.write(filepath, base64)
    return
  end

  expect(File.open(filepath)).to(eq(base64), "#{filename} golden match fail")
end
