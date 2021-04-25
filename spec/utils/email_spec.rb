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
    # rubocop:disable Style/StringHashKeys
    expect_any_instance_of(SendGrid::Client).to(receive(:post)).once.with(
        hash_including(request_body: hash_including(
            'content' => [
              hash_including('value' => a_string_matching(poll.id))
            ])))
    # rubocop:enable Style/StringHashKeys
    Utils::Email.email(poll, poll.responders.first)
  }
}
