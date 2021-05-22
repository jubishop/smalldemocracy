require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  context('::create') {
    it('creates a poll with comma strings') {
      poll = create(choices: 'one, two, three', responders: 'a@b, b@c, c@d')
      expect(poll.choices.map(&:text)).to(match_array(%w[one two three]))
      expect(poll.responders.map(&:email)).to(match_array(%w[a@b b@c c@d]))
    }

    it('creates a poll with arrays') {
      poll = create(choices: %w[four five six],
                    responders: ['d@e', 'e@f', 'f@g'])
      expect(poll.choices.map(&:text)).to(match_array(%w[four five six]))
      expect(poll.responders.map(&:email)).to(match_array(%w[d@e e@f f@g]))
    }

    it('defaults to creating a poll that is `borda_single` type') {
      poll = create
      expect(poll.type).to(eq(:borda_single))
    }

    it('can be created with other valid types') {
      poll = create(type: :borda_split)
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creation of invalid type') {
      expect {  create(type: :not_valid_type) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two choices with the same text') {
      expect {  create(choices: %w[one one]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a choice with empty text') {
      expect {  create(choices: ['one', '']) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responders with the same email') {
      expect {  create(responders: %w[a@a a@a]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a responder with empty email') {
      expect {  create(responders: ['a@a', '']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creating a responder with invalid email address') {
      expect {  create(responders: ['not_an_email_address']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creation without responders or choices') {
      expect {  create(choices: nil) }.to(raise_error(Models::ArgumentError))
      expect {  create(responders: nil) }.to(raise_error(Models::ArgumentError))
      expect {  create(choices: '') }.to(raise_error(Models::ArgumentError))
      expect {  create(responders: '') }.to(raise_error(Models::ArgumentError))
      expect {  create(choices: []) }.to(raise_error(Models::ArgumentError))
      expect {  create(responders: []) }.to(raise_error(Models::ArgumentError))
    }

    it('fatals if require fields are missing or empty') {
      expect {
        create(title: '')
      }.to(raise_error(Sequel::ConstraintViolation))
      expect {  create(title: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
      expect {  create(question: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect {  create(question: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
      expect {  create(expiration: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect {  create(expiration: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
    }
  }

  context('#results') {
    it('raises error if using scores on choose_* types') {
      poll = create(type: :choose_one)
      expect { poll.scores }.to(raise_error(Models::TypeError))
    }

    it('raises error if using breakdown on borda_* types') {
      poll = create(type: :borda_single)
      expect { poll.breakdown }.to(raise_error(Models::TypeError))
      poll = create(type: :borda_split)
      expect { poll.breakdown }.to(raise_error(Models::TypeError))
    }

    context(':borda_single') {
      it('computes scores properly') {
        choices = %w[one two three four five]
        responders = %w[a@a b@b c@c d@d e@e]
        poll = create(choices: choices, responders: responders)

        responses = {
          'a@a': %w[one two five three four],
          'b@b': %w[one two four three five],
          'c@c': %w[three one two four five],
          'd@d': %w[four two three one five],
          'e@e': %w[three one two four five]
        }
        responses.each { |email, ranks|
          responder = poll.responder(email: email.to_s)
          poll.choices.each { |choice|
            responder.add_response(choice_id: choice.id,
                                   rank: ranks.index(choice.text),
                                   chosen: true)
          }
        }

        poll.expiration = 1
        results = { one: 15, two: 13, three: 12, four: 8, five: 2 }
        results.each_with_index { |result, index|
          choice, score = *result
          expect(poll.scores[index].text).to(eq(choice.to_s))
          expect(poll.scores[index].score).to(eq(score))
        }
      }
    }

    context(':borda_split') {
      before(:each) {
        choices = %w[one two three four five]
        responders = %w[a@a b@b c@c d@d e@e]
        @poll = create(choices: choices,
                       responders: responders,
                       type: :borda_split)

        responses = {
          'a@a': %w[one two],
          'b@b': %w[one two five four],
          'c@c': %w[two three five one],
          'd@d': %w[two five three],
          'e@e': %w[two one]
        }

        responses.each { |email, chosen_ranks|
          responder = @poll.responder(email: email.to_s)
          @poll.choices.each { |choice|
            if chosen_ranks.include?(choice.text)
              responder.add_response(choice_id: choice.id,
                                     rank: chosen_ranks.index(choice.text),
                                     chosen: true)
            else
              responder.add_response(choice_id: choice.id, chosen: false)
            end
          }
        }

        @poll.expiration = 1
      }

      it('computes scores properly') {
        score_results = { two: 18, one: 12, five: 7, three: 5, four: 1 }
        score_results.each_with_index { |result, index|
          choice, score = *result
          expect(@poll.scores[index].text).to(eq(choice.to_s))
          expect(@poll.scores[index].score).to(eq(score))
        }
      }

      it('computes counts properly') {
        count_results = { two: 5, one: 4, five: 3, three: 2, four: 1 }
        count_results.each_with_index { |result, index|
          choice, count = *result
          expect(@poll.counts[index].text).to(eq(choice.to_s))
          expect(@poll.counts[index].count).to(eq(count))
        }
      }
    }

    context(':choose_one') {
      before(:each) {
        choices = %w[yes no maybe]
        responders = %w[a@a b@b c@c d@d e@e f@f]
        @poll = create(choices: choices,
                       responders: responders,
                       type: :choose_one)

        responses = {
          'a@a': 'yes',
          'b@b': 'no',
          'c@c': 'yes',
          'd@d': 'maybe',
          'e@e': 'yes',
          'f@f': 'maybe'
        }

        responses.each { |email, choice|
          responder = @poll.responder(email: email.to_s)
          choice = @poll.choice(text: choice)
          responder.add_response(choice_id: choice.id, chosen: true)
        }
      }

      it('computes breakdown properly') {
        breakdown_results = {
          yes: ['a@a', 'c@c', 'e@e'],
          maybe: ['d@d', 'f@f'],
          no: ['b@b']
        }
        breakdown = @poll.breakdown
        breakdown.each { |choice, responders|
          expect(breakdown_results[choice.text.to_sym]).to(
              eq(responders.map(&:email).sort))
        }
      }

      it('computes counts properly') {
        count_results = { yes: 3, maybe: 2, no: 1 }
        count_results.each_with_index { |result, index|
          choice, count = *result
          expect(@poll.counts[index].text).to(eq(choice.to_s))
          expect(@poll.counts[index].count).to(eq(count))
        }
      }
    }
  }
}
