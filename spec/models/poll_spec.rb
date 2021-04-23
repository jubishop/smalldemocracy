require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  let(:basic_options) {
    {
      title: 'title',
      question: 'question',
      expiration: 123
    }
  }

  context('::create_poll') {
    it('creates a poll with comma strings') {
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: 'one, two, three',
                                      responders: 'a@b, b@c, c@d')
      expect(poll.choices.map(&:text)).to(match_array(%w[one two three]))
      expect(poll.responders.map(&:email)).to(match_array(%w[a@b b@c c@d]))
    }

    it('creates a poll with arrays') {
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: %w[four five six],
                                      responders: ['d@e', 'e@f', 'f@g'])
      expect(poll.choices.map(&:text)).to(match_array(%w[four five six]))
      expect(poll.responders.map(&:email)).to(match_array(%w[d@e e@f f@g]))
    }
  }

  context('#results') {
    it('returns no results if the poll is not expired') {
      allow(Time).to(receive(:now).and_return(Time.at(0)))
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: [],
                                      responders: [])
      expect(poll.results).to(be_falsey)
    }

    it('computes results properly') {
      choices = %w[one two three four]
      responders = %w[a b c d]
      allow(Time).to(receive(:now).and_return(Time.now + 100))
      poll = Models::Poll.create_poll(**basic_options,
                                      choices: choices,
                                      responders: responders)

      responses = {
        a: %w[one two three four],
        b: %w[one two four three],
        c: %w[three one two four],
        d: %w[four two three one]
      }
      responses.each { |email, ranks|
        responder = poll.responder(email: email.to_s)
        poll.choices.each { |choice|
          responder.add_response(choice_id: choice.id,
                                 rank: ranks.index(choice.text))
        }
      }

      results = { one: 8, two: 7, three: 5, four: 4 }
      results.each_with_index { |result, index|
        choice, score = *result
        expect(poll.results[index].text).to(eq(choice.to_s))
        expect(poll.results[index].score).to(eq(score))
      }
    }
  }
}
