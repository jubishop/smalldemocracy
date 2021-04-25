require 'sendgrid-ruby'

require_relative '../../lib/utils/email'

RSpec.describe(Utils::Email) {
  before(:all) {
    RSpec::Mocks.configuration.verify_partial_doubles = false
  }

  after(:all) {
    RSpec::Mocks.configuration.verify_partial_doubles = true
  }

  it('sends email') {
    ENV['APP_ENV'] = 'development'
    poll = create_poll(responders: 'jubi@hey.com')
    allow(Process).to(receive(:detach))
    allow(Process).to(receive(:fork)) { |&arg| arg.call }
    expect_any_instance_of(SendGrid::Client).to(receive(:post)).once { |_, data|
      node = Capybara.string(data[:request_body]['content'].first['value'])
      base = 'https://www.jubivote.com/poll/view/'
      query = "#{poll.id}?responder=#{poll.responders.first.salt}"
      expect(node).to(have_link('click here', href: "#{base}#{query}"))
    }
    Utils::Email.email(poll, poll.responders.first)
  }
}
