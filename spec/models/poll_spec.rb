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
      expect { create(type: :not_valid_type) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two choices with the same text') {
      expect { create(choices: %w[one one]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a choice with empty text') {
      expect { create(choices: ['one', '']) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responders with the same email') {
      expect { create(responders: %w[a@a a@a]) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a responder with empty email') {
      expect { create(responders: ['a@a', '']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creating a responder with invalid email address') {
      expect { create(responders: ['not_an_email_address']) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creation without responders or choices') {
      expect { create(choices: nil) }.to(raise_error(Models::ArgumentError))
      expect { create(responders: nil) }.to(raise_error(Models::ArgumentError))
      expect { create(choices: '') }.to(raise_error(Models::ArgumentError))
      expect { create(responders: '') }.to(raise_error(Models::ArgumentError))
      expect { create(choices: []) }.to(raise_error(Models::ArgumentError))
      expect { create(responders: []) }.to(raise_error(Models::ArgumentError))
    }

    it('fatals if require fields are missing or empty') {
      expect { create(title: '') }.to(raise_error(Sequel::ConstraintViolation))
      expect { create(title: nil) }.to(raise_error(Sequel::ConstraintViolation))
      expect { create(question: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create(question: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create(expiration: '') }.to(
          raise_error(Sequel::ConstraintViolation))
      expect { create(expiration: nil) }.to(
          raise_error(Sequel::ConstraintViolation))
    }
  }

  context('#url') {
    before(:each) {
      @poll = create
    }

    it('creates plain url with no responder') {
      expect(@poll.url).to(eq("/poll/view/#{@poll.id}"))
    }

    it('creates url with responder') {
      responder = @poll.add_responder(email: 'yo@yo')
      expect(@poll.url(responder)).to(
          eq("/poll/view/#{@poll.id}?responder=#{responder.salt}"))
    }

    it('throws error if trying to create URL of responder not in poll') {
      poll = create
      another_poll = create
      responder = another_poll.add_responder(email: 'yo@yo.com')
      expect { poll.url(responder) }.to(raise_error(Models::ArgumentError))
    }
  }

  context('#results') {
    it('raises error if using scores on choose_* types') {
      poll = create(type: :choose_one)
      expect { poll.scores }.to(raise_error(Models::TypeError))
    }

    it('raises an error if using counts on borda_single type') {
      poll = create(type: :borda_single)
      expect { poll.counts }.to(raise_error(Models::TypeError))
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
          'b@b': %w[one five four two],
          'c@c': %w[one three five two],
          'd@d': %w[five three two],
          'e@e': %w[one five]
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
        score_results = { one: 16, five: 12, two: 7, three: 6, four: 2 }
        score_results.each_with_index { |result, index|
          choice, score = *result
          expect(@poll.scores[index].text).to(eq(choice.to_s))
          expect(@poll.scores[index].score).to(eq(score))
        }
      }

      it('computes counts properly') {
        count_results = { one: 4, five: 4, two: 4, three: 2, four: 1 }
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
        responders = %w[a@a b@b c@c d@d e@e f@f g@g]
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
        results_expected = {
          yes: ['a@a', 'c@c', 'e@e'],
          maybe: ['d@d', 'f@f'],
          no: ['b@b']
        }
        unresponded_expected = ['g@g']
        results, unresponded = @poll.breakdown
        expect(unresponded_expected).to(match_array(unresponded.map(&:email)))
        results.each { |choice, responders|
          expect(results_expected[choice.text.to_sym]).to(
              match_array(responders.map(&:email)))
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
