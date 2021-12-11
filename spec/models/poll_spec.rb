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
          raise_error(Sequel::DatabaseError))
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
          raise_error(Sequel::HookFailed, 'Email: , is invalid'))
    }

    it('rejects creating a responder with invalid email address') {
      expect { create(responders: ['not_an_email']) }.to(
          raise_error(Sequel::HookFailed, 'Email: not_an_email, is invalid'))
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
      expect { create(title: '') }.to(raise_error(Models::ArgumentError))
      expect { create(title: nil) }.to(raise_error(Models::ArgumentError))
      expect { create(question: '') }.to(raise_error(Models::ArgumentError))
      expect { create(question: nil) }.to(raise_error(Models::ArgumentError))
      expect { create(expiration: '') }.to(raise_error(Models::ArgumentError))
      expect { create(expiration: nil) }.to(raise_error(Models::ArgumentError))
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

    shared_examples('computability') {
      it('computes breakdown properly') {
        breakdown, unresponded = @poll.breakdown
        expect(@expected_unresponded).to(match_array(unresponded.map(&:email)))
        expect(breakdown.length).to(eq(@expected_results.length))
        breakdown.each { |choice, results|
          expected_result = @expected_results[choice.text.to_sym]
          expect(results.length).to(be(expected_result.length))
          results.each { |result|
            email = result.responder.email
            expect(result.score).to(
                eq(expected_result[email.to_sym]),
                "expected #{expected_result[email.to_sym]} for #{choice.text}" \
                " => #{email} but got #{result.score}")
          }
        }
      }

      it('computes scores properly') {
        results = @expected_results.transform_values { |v| v.values.sum }
        expect(@poll.scores.length).to(be(results.length))
        results.sort_by { |_, v| -v }.each_with_index { |result, index|
          choice, score = *result
          expect(@poll.scores[index].text).to(
              eq(choice.to_s),
              "expected #{choice} for position #{index} but got " \
              "#{@poll.scores[index].text}")
          expect(@poll.scores[index].score).to(
              eq(score),
              "expected #{score} for #{choice} but got " \
              "#{@poll.scores[index].score}")
        }
      }
    }

    context(':borda_single') {
      before(:each) {
        choices = %w[one two three four five six]
        responders = %w[a@a b@b c@c d@d e@e f@f]
        @poll = create(choices: choices, responders: responders)

        responses = {
          'a@a': %w[one two five three four six],
          'b@b': %w[one two four three five six],
          'c@c': %w[three one two four five six],
          'd@d': %w[four two three one five six],
          'e@e': %w[three one two four five six]
        }
        responses.each { |email, ranks|
          responder = @poll.responder(email: email.to_s)
          @poll.choices.each { |choice|
            score = choices.length - ranks.index(choice.text) - 1
            responder.add_response(choice_id: choice.id, score: score)
          }
        }

        @expected_results = {
          one: { 'a@a': 5, 'b@b': 5, 'c@c': 4, 'd@d': 2, 'e@e': 4 },
          two: { 'a@a': 4, 'b@b': 4, 'c@c': 3, 'd@d': 4, 'e@e': 3 },
          three: { 'a@a': 2, 'b@b': 2, 'c@c': 5, 'd@d': 3, 'e@e': 5 },
          four: { 'a@a': 1, 'b@b': 3, 'c@c': 2, 'd@d': 5, 'e@e': 2 },
          five: { 'a@a': 3, 'b@b': 1, 'c@c': 1, 'd@d': 1, 'e@e': 1 },
          six: { 'a@a': 0, 'b@b': 0, 'c@c': 0, 'd@d': 0, 'e@e': 0 }
        }
        @expected_unresponded = ['f@f']

        @poll.expiration = 1
      }

      it_has_behavior('computability')
    }

    context(':borda_split') {
      before(:each) {
        choices = %w[one two three four five six]
        responders = %w[a@a b@b c@c d@d e@e f@f]
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
              score = choices.length - chosen_ranks.index(choice.text)
              responder.add_response(choice_id: choice.id, score: score)
            end
          }
        }

        @expected_results = {
          one: { 'a@a': 6, 'b@b': 6, 'c@c': 6, 'e@e': 6 },
          two: { 'a@a': 5, 'b@b': 3, 'c@c': 3, 'd@d': 4 },
          three: { 'c@c': 5, 'd@d': 5 },
          four: { 'b@b': 4 },
          five: { 'b@b': 5, 'c@c': 4, 'd@d': 6, 'e@e': 5 }
        }
        @expected_unresponded = ['f@f']

        @poll.expiration = 1
      }

      it('computes counts properly') {
        count_results = @expected_results.transform_values(&:length)
        count_results = count_results.sort_by { |k, v|
          [-v, -@expected_results[k].values.sum]
        }
        expect(@poll.counts.length).to(be(count_results.length))
        count_results.each_with_index { |result, index|
          choice, count = *result
          expect(@poll.counts[index].text).to(eq(choice.to_s))
          expect(@poll.counts[index].count).to(eq(count))
        }
      }

      it_has_behavior('computability')
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
          responder.add_response(choice_id: choice.id)
        }
      }

      it('computes breakdown properly') {
        results_expected = {
          yes: ['a@a', 'c@c', 'e@e'],
          maybe: ['d@d', 'f@f'],
          no: ['b@b']
        }
        expected_unresponded = ['g@g']
        breakdown, unresponded = @poll.breakdown
        expect(expected_unresponded).to(match_array(unresponded.map(&:email)))
        expect(breakdown.length).to(be(3))
        breakdown.each { |choice, results|
          expect(results_expected[choice.text.to_sym]).to(
              match_array(results.map { |result| result[:responder].email }))
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
