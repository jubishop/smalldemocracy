require 'sendgrid-ruby'

require_relative '../../lib/utils/email'

RSpec.describe(Utils::Email) {
  before(:all) {
    RSpec::Mocks.configuration.verify_partial_doubles = false
  }

  after(:all) {
    RSpec::Mocks.configuration.verify_partial_doubles = true
  }

  before(:each) {
    ENV['APP_ENV'] = 'development'
    allow(Process).to(receive(:detach))
    allow(Process).to(receive(:fork)) { |&arg| arg.call }
  }

  it('sends email') {
    poll =  create(responders: 'jubi@hey.com')
    expect_any_instance_of(SendGrid::Client).to(receive(:post)).once { |_, data|
      expect(data[:request_body]['personalizations'].first).to(eq({
        # rubocop:disable Style/StringHashKeys
        'to' => [{ 'email' => 'jubi@hey.com' }]
        # rubocop:enable Style/StringHashKeys
      }))
      node = Capybara.string(data[:request_body]['content'].first['value'])
      url = "https://www.#{Utils::Email::HOSTNAME}#{poll.responders.first.url}"
      expect(node).to(have_link('click here', href: url))
    }
    Utils::Email.email(poll, poll.responders.first)
  }

  it('rejects sending email to expired poll') {
    poll = create(responders: 'jubi@hey.com', expiration: 1)
    expect { Utils::Email.email(poll, poll.responders.first) }.to(
        raise_error(Utils::ArgumentError))
  }
}
