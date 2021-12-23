require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  context('add_choice') {
    it('rejects creating two choices with the same text') {
      poll = create_poll
      poll.add_choice(text: 'one')
      expect { poll.add_choice(text: 'one') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a choice with empty text') {
      poll = create_poll
      expect { poll.add_choice(text: '') }.to(
          raise_error(Sequel::DatabaseError))
    }
  }

  context('members') {
    it('finds members from its group') {
      group = create_group
      group.add_member
      poll = group.add_poll
      expect(poll.members).to(match_array(group.members))
    }
  }

  context('member') {
    it('finds a member from its group') {
      group = create_group
      member = group.add_member
      poll = group.add_poll
      expect(poll.member(email: member.email)).to(eq(member))
    }
  }

  context('choice') {
    it('finds a choice') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choice(text: choice.text)).to(eq(choice))
    }
  }

  context('creator') {
    it('finds creator') {
      user = create_user
      group = user.add_group
      poll = group.add_poll
      expect(poll.creator).to(eq(user))
    }
  }

  context('finished?') {
    it('returns a unexpired poll as unfinished') {
      poll = create_poll(expiration: Time.now + 10)
      expect(poll.finished?).to(be(false))
    }

    it('returns an expired poll as finished') {
      poll = create_poll(expiration: Time.now - 10)
      expect(poll.finished?).to(be(true))
    }
  }

  context('url') {
    it('creates url') {
      poll = create_poll
      expect(poll.url).to(eq("/poll/view/#{poll.id}"))
    }
  }

  context('results') {
    it('raises error if using scores on choose_* types') {
      poll = create_poll(type: :choose_one)
      expect { poll.scores }.to(raise_error(TypeError))
    }

    it('raises an error if using counts on borda_single type') {
      poll = create_poll(type: :borda_single)
      expect { poll.counts }.to(raise_error(TypeError))
    }

    shared_examples('breakdown') {
      it('computes breakdown properly') {
        breakdown, unresponded = @poll.breakdown
        expect(unresponded.map(&:email)).to(match_array(@expected_unresponded))
        expect(@expected_results.keys.map(&:to_s)).to(
            match_array(breakdown.keys.map(&:text)))
        breakdown.each { |choice, results|
          expected_result = @expected_results[choice.to_s.to_sym]
          expect(expected_result.keys).to(
              match_array(results.map { |r| r.member.email.to_sym }))
          expect(expected_result.values).to(match_array(results.map(&:score)))
        }
      }
    }

    shared_examples('scores') {
      it('computes scores properly') {
        results = @expected_results.transform_values { |v| v.values.sum }
        results = results.sort_by { |_, v| -v }
        expect(@poll.scores.map(&:to_s)).to(
            match_array(results.map { |r| r[0].to_s }))
        expect(@poll.scores).to(match_array(results.map { |r| r[1] }))
      }
    }

    shared_examples('counts') {
      it('computes counts properly') {
        results = @expected_results.transform_values(&:length).sort_by { |k, v|
          [-v, -@expected_results[k].values.sum(&:to_i)]
        }
        expect(@poll.counts.map(&:to_s)).to(
            match_array(results.map { |r| r[0].to_s }))
        expect(@poll.counts.map(&:count)).to(
            match_array(results.map { |r| r[1] }))
      }
    }

    context(':borda_single') {
      before(:all) {
        choices = %w[one two three four five six]
        members = %w[a@a b@b c@c d@d e@e f@f]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(expiration: Time.now + 10)
        choices.each { |choice| @poll.add_choice(text: choice) }

        responses = {
          'a@a': %w[one two five three four six],
          'b@b': %w[one two four three five six],
          'c@c': %w[three one two four five six],
          'd@d': %w[four two three one five six],
          'e@e': %w[three one two four five six]
        }
        responses.each { |email, ranks|
          member = @poll.member(email: email.to_s)
          @poll.choices.each { |choice|
            score = choices.length - ranks.index(choice.text) - 1
            member.add_response(choice_id: choice.id, score: score)
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
        @expected_unresponded = ['f@f', @poll.creator.email]

        @poll.expiration = 1
      }

      it_has_behavior('breakdown')
      it_has_behavior('scores')
    }

    context(':borda_split') {
      before(:each) {
        choices = %w[one two three four five six]
        members = %w[a@a b@b c@c d@d e@e f@f]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(type: :borda_split, expiration: Time.now + 10)
        choices.each { |choice| @poll.add_choice(text: choice) }

        responses = {
          'a@a': %w[one two],
          'b@b': %w[one five four two],
          'c@c': %w[one three five two],
          'd@d': %w[five three two],
          'e@e': %w[one five]
        }
        responses.each { |email, chosen_ranks|
          member = @poll.member(email: email.to_s)
          @poll.choices.each { |choice|
            if chosen_ranks.include?(choice.text)
              score = choices.length - chosen_ranks.index(choice.text)
              member.add_response(choice_id: choice.id, score: score)
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
        @expected_unresponded = ['f@f', @poll.creator.email]

        @poll.expiration = 1
      }

      it_has_behavior('breakdown')
      it_has_behavior('scores')
      it_has_behavior('counts')
    }

    context(':choose_one') {
      before(:each) {
        choices = %w[yes no maybe]
        members = %w[a@a b@b c@c d@d e@e f@f g@g]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(type: :choose_one, expiration: Time.now + 10)
        choices.each { |choice| @poll.add_choice(text: choice) }

        responses = {
          'a@a': 'yes',
          'b@b': 'no',
          'c@c': 'yes',
          'd@d': 'maybe',
          'e@e': 'yes',
          'f@f': 'maybe'
        }
        responses.each { |email, choice|
          member = @poll.member(email: email.to_s)
          choice = @poll.choice(text: choice)
          member.add_response(choice_id: choice.id)
        }

        @expected_results = {
          yes: { 'a@a': nil, 'c@c': nil, 'e@e': nil },
          maybe: { 'd@d': nil, 'f@f': nil },
          no: { 'b@b': nil }
        }
        @expected_unresponded = ['g@g', @poll.creator.email]
      }

      it_has_behavior('breakdown')
      it_has_behavior('counts')
    }
  }
}
