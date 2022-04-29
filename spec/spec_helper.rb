require 'capybara/apparition'
require 'colorize'
require 'core/test'
require 'sequel'
require 'tony/test'
require 'tzinfo'

require_relative '../development_helpers'
stub_environment_vars('test')
ENV['RESET_DB_ON_SETUP'] = '1' # NEVER SET THIS ANYWHERE ELSE

require_relative '../setup'

require_relative 'helpers/email'
require_relative 'helpers/matchers'
require_relative 'helpers/models'
require_relative 'helpers/time'

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

RSpec.shared_context(:migration) {
  let(:DB) { Sequel::DATABASES.first }

  before(:each) {
    Sequel::Migrator.run(DB, 'db/migrations', target: 0)
  }

  after(:each) {
    Sequel::Migrator.run(DB, 'db/migrations')
  }
}

RSpec.shared_context(:model) {
  let(:email) { random_email }
}

RSpec.shared_context(:web_test) {
  let(:cookie_secret) { ENV.fetch('SMALLDEMOCRACY_COOKIE_SECRET') }
  let(:email) { random_email }
  before(:each) { set_cookie(:email, email) }
}

RSpec.shared_context(:rack_test) {
  include_context(:tony_rack_test)
  include_context(:web_test)

  let(:app) { Capybara.app }

  # rubocop:disable Style/StringHashKeys
  def post_json(path, data = {})
    post(path, data.to_json, { 'CONTENT_TYPE' => 'application/json' })
  end
  # rubocop:enable Style/StringHashKeys
}

RSpec.shared_context(:capybara) {
  include_context(:tony_capybara)
  include_context(:web_test)

  def go(path)
    page.driver.set_cookie(:tz, 'Asia/Bangkok')
    visit(path)
    expect(page).to(have_assets)
    expect(page).to(have_fonts)
    expect(page).to(have_fontawesome)
    expect(page).to(have_timezone)
    page.driver.set_cookie(:tz, 'Asia/Bangkok')
  end
}

RSpec.configure do |config|
  config.expect_with(:rspec) do |expect|
    expect.include_chain_clauses_in_custom_matcher_descriptions = true
    expect.max_formatted_output_length = 200
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.default_formatter = 'doc'
  config.alias_it_should_behave_like_to(:it_has_behavior, 'has behavior:')

  config.order = :random
  Kernel.srand(config.seed)

  config.include(RSpec::EMail)
  config.include(RSpec::Models)
  config.include(RSpec::Time)
  config.include_context(:migration, type: :migration)
  config.include_context(:model, type: :model)
  config.include_context(:rack_test, type: :rack_test)
  config.include_context(:capybara, type: :feature)

  config.before(:each) {
    freeze_time(Time.at(Time.now, in: TZInfo::Timezone.get('America/New_York')))
    allow(Tony::Auth::Google).to(receive(:url)) { |_, r: '/'| r }
    allow(Tony::Auth::Github).to(receive(:url)) { |_, r: '/'| r }
    allow(Tony::Auth::Facebook).to(receive(:url)) { |_, r: '/'| r }
  }

  config.after(:each) {
    ENV['APP_ENV'] = 'test'
    ENV['RACK_ENV'] = 'test'
  }

  if ENV.fetch('FAIL_ON_GOLDEN', false) || Test::Env.github_actions?
    require 'rspec/retry'
    require 'sequel'

    config.around(:each, :feature, &:run_with_retry)
    config.default_retry_count = 4
    config.display_try_failure_messages = true
    config.verbose_retry = true
    config.retry_callback = proc {
      Capybara.reset!
      Sequel::Migrator.run(DB, 'db/migrations', target: 0)
      Sequel::Migrator.run(DB, 'db/migrations')
    }
  end
end
