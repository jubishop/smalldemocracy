require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  context('::create_poll') {
    let(:basic_options) {
      {
        title: 'title',
        question: 'question',
        expiration: 123
      }
    }

    it('creates a poll with comma strings') {
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: 'one, two, three',
                                      responders: 'a@b, b@c, c@d')
      expect(poll.choices.map(&:text)).to(match_array(%w[one two three]))
      expect(poll.responders.map(&:email)).to(match_array(%w[a@b b@c c@d]))
    }

    it('creates a poll with arrays') {
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: ['one', 'two', 'three'],
                                      responders: ['a@b', 'b@c', 'c@d'])
      expect(poll.choices.map(&:text)).to(match_array(%w[one two three]))
      expect(poll.responders.map(&:email)).to(match_array(%w[a@b b@c c@d]))
    }
  }
}
