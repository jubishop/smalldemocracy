require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  context('::create_poll') {
    it('creates a poll with comma strings') {
      poll = create_poll(choices: 'one, two, three',
                         responders: 'a@b, b@c, c@d')
      expect(poll.choices.map(&:text)).to(match_array(%w[one two three]))
      expect(poll.responders.map(&:email)).to(match_array(%w[a@b b@c c@d]))
    }

    it('creates a poll with arrays') {
      poll = create_poll(choices: %w[four five six],
                         responders: ['d@e', 'e@f', 'f@g'])
      expect(poll.choices.map(&:text)).to(match_array(%w[four five six]))
      expect(poll.responders.map(&:email)).to(match_array(%w[d@e e@f f@g]))
    }

    it('defaults to creating a poll that is `borda_single` type') {
      poll = create_poll
      expect(poll.type).to(eq(:borda_single))
    }

    it('can be created with other types') {
      poll = create_poll(type: :borda_split)
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creation of invalid type') {
      expect { create_poll(type: :not_valid_type) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two choices with the same text') {
      expect { create_poll(choices: %w[one one]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a choice with empty text') {
      expect { create_poll(choices: ['one', '']) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responders with the same email') {
      expect { create_poll(responders: %w[a@a a@a]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a responder with empty email') {
      expect { create_poll(responders: ['a@a', '']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creating a responder with invalid email address') {
      expect { create_poll(responders: ['not_an_email_address']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creation without responders or choices') {
      expect { create_poll(choices: nil) }.to(raise_error(ArgumentError))
      expect { create_poll(responders: nil) }.to(raise_error(ArgumentError))
      expect { create_poll(choices: '') }.to(raise_error(ArgumentError))
      expect { create_poll(responders: '') }.to(raise_error(ArgumentError))
      expect { create_poll(choices: []) }.to(raise_error(ArgumentError))
      expect { create_poll(responders: []) }.to(raise_error(ArgumentError))
    }

    it('fatals if require fields are missing or empty') {
      expect { create_poll(title: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create_poll(title: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create_poll(question: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create_poll(question: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create_poll(expiration: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create_poll(expiration: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
    }
  }

  context('#results') {
    it('returns no results if the poll is not expired') {
      allow(Time).to(receive(:now).and_return(Time.at(0)))
      poll = create_poll(choices: 'a', responders: 'b@b')
      expect(poll.scores).to(be_falsey)
      expect(poll.counts).to(be_falsey)
    }

    it('computes results properly') {
      choices = %w[one two three four]
      responders = %w[a@a b@b c@c d@d]
      poll = create_poll(choices: choices, responders: responders)

      responses = {
        'a@a': %w[one two three four],
        'b@b': %w[one two four three],
        'c@c': %w[three one two four],
        'd@d': %w[four two three one]
      }
      responses.each { |email, ranks|
        responder = poll.responder(email: email.to_s)
        poll.choices.each { |choice|
          responder.add_response(choice_id: choice.id,
                                 rank: ranks.index(choice.text))
        }
      }

      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      results = { one: 8, two: 7, three: 5, four: 4 }
      results.each_with_index { |result, index|
        choice, score = *result
        expect(poll.scores[index].text).to(eq(choice.to_s))
        expect(poll.scores[index].score).to(eq(score))
      }
    }
  }
}
