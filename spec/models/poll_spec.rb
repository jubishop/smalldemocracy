require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll) {
  context('create') {
    it('creates a poll') {
      now = Time.now
      poll = create_poll(email: 'me@email',
                         title: 'title',
                         question: 'question',
                         expiration: now,
                         type: :borda_split)
      expect(poll.email).to(eq('me@email'))
      expect(poll.title).to(eq('title'))
      expect(poll.question).to(eq('question'))
      expect(poll.expiration).to(eq(now))
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creating poll with no title') {
      expect { create_poll(title: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "title"/))
    }

    it('rejects creating poll with empty title') {
      expect { create_poll(title: '') }.to(
          raise_error(Sequel::CheckConstraintViolation,
                      /violates check constraint "title_not_empty"/))
    }

    it('rejects creating poll with no question') {
      expect { create_poll(question: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "question"/))
    }

    it('rejects creating poll with empty question') {
      expect { create_poll(question: '') }.to(
          raise_error(Sequel::CheckConstraintViolation,
                      /violates check constraint "question_not_empty"/))
    }

    it('rejects creating poll with no expiration') {
      expect { create_poll(expiration: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "expiration"/))
    }

    it('rejects creating a poll with expiration at unix epoch') {
      expect { create_poll(expiration: Time.at(0)) }.to(
          raise_error(Sequel::HookFailed,
                      'Poll has expiration at unix epoch'))
    }

    it('defaults to creating a poll that is `borda_single` type') {
      expect(create_poll.type).to(eq(:borda_single))
    }

    it('rejects creating polls of invalid type') {
      expect { create_poll(type: :not_valid_type) }.to(
          raise_error(Sequel::DatabaseError,
                      /invalid input value for enum poll_type/))
    }
  }

  context('destroy') {
    it('destroys itself from group') {
      group = create_group
      poll = group.add_poll(expiration: future)
      expect(group.polls).to_not(be_empty)
      expect(poll.exists?).to(be(true))
      group.remove_poll(poll)
      expect(group.polls).to(be_empty)
      expect(poll.exists?).to(be(false))
    }

    it('destroys itself from user') {
      user = create_user
      poll = user.add_poll(group_id: user.add_group.id, expiration: future)
      expect(user.polls).to_not(be_empty)
      expect(poll.exists?).to(be(true))
      user.remove_poll(poll)
      expect(user.polls).to(be_empty)
      expect(poll.exists?).to(be(false))
    }

    it('cascades destroy to choices') {
      poll = create_poll
      choice = poll.add_choice
      expect(choice.exists?).to(be(true))
      poll.destroy
      expect(choice.exists?).to(be(false))
    }
  }

  context('creator') {
    it('finds its creator') {
      user = create_user
      group = user.add_group
      poll = group.add_poll(email: user.email)
      expect(poll.creator).to(eq(user))
    }
  }

  context('group') {
    it('finds its group') {
      group = create_group
      poll = group.add_poll
      expect(poll.group).to(eq(group))
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

  context('creating_member') {
    it('finds its creating member') {
      group = create_group
      member = group.add_member
      poll = member.add_poll
      expect(poll.creating_member).to(eq(member))
    }
  }

  context('choice') {
    it('finds a choice') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choice(text: choice.text)).to(eq(choice))
    }
  }

  context('finished?') {
    it('returns an open poll as unfinished') {
      poll = create_poll
      expect(poll.finished?).to(be(false))
    }

    it('returns an expired poll as finished') {
      poll = create_poll(expiration: past)
      expect(poll.finished?).to(be(true))
    }
  }

  context('results') {
    it('raises error if using scores on choose_* types') {
      poll = create_poll(type: :choose_one)
      expect { poll.scores }.to(
          raise_error(TypeError, /must be one of borda_single or borda_split/))
    }

    it('raises an error if using counts on borda_single type') {
      poll = create_poll(type: :borda_single)
      expect { poll.counts }.to(
          raise_error(TypeError, /must be one of borda_split or choose_one/))
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

    shared_examples('breakdown') {
      it('computes breakdown properly') {
        breakdown, unresponded = @poll.breakdown
        expect(unresponded.map(&:email)).to(match_array(@expected_unresponded))
        expect(breakdown.keys.map(&:text)).to(
            match_array(@expected_results.keys.map(&:to_s)))
        breakdown.each { |choice, results|
          expected_result = @expected_results[choice.to_s.to_sym]
          expect(results.map { |r| r.member.email.to_sym }).to(
              match_array(expected_result.keys))
          expect(results.map(&:score)).to(match_array(expected_result.values))
        }
      }
    }

    context(':borda_single') {
      before(:all) {
        choices = %w[one two three four five six]
        members = %w[a@a b@b c@c d@d e@e f@f]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(expiration: future)
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
        @expected_unresponded = ['f@f', group.creator.email]

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

        @poll = group.add_poll(type: :borda_split, expiration: future)
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
        @expected_unresponded = ['f@f', group.creator.email]

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

        @poll = group.add_poll(type: :choose_one, expiration: future)
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
        @expected_unresponded = ['g@g', group.creator.email]
      }

      it_has_behavior('breakdown')
      it_has_behavior('counts')
    }
  }

  context('url') {
    it('creates url') {
      poll = create_poll
      expect(poll.url).to(eq("/poll/view/#{poll.hashid}"))
    }
  }

  context('add_choice') {
    it('adds a choice') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choices).to(match_array(choice))
    }

    it('rejects adding a choice to an expired poll') {
      poll = create_poll(expiration: past)
      expect { poll.add_choice }.to(
          raise_error(Sequel::HookFailed, 'Choice modified in expired poll'))
    }

    it('rejects creating two choices with the same text') {
      poll = create_poll
      poll.add_choice(text: 'one')
      expect { poll.add_choice(text: 'one') }.to(
          raise_error(Sequel::ConstraintViolation,
                      /violates unique constraint "choice_unique"/))
    }
  }

  context('responses') {
    it('finds all responses through join table') {
      poll = create_poll
      response_one = poll.add_choice.add_response
      response_two = poll.add_choice.add_response
      expect(poll.responses).to(match_array([response_one, response_two]))
    }
  }

  context('timestamps') {
    it('sets updated_at and created_at upon creation') {
      moment = freeze_time
      poll = create_poll
      expect(poll.created_at).to(eq(moment))
      expect(poll.updated_at).to(eq(moment))
    }

    it('sets updated_at upon update') {
      poll = create_poll
      moment = freeze_time
      poll.update(title: 'title')
      expect(poll.created_at).to_not(eq(poll.updated_at))
      expect(poll.updated_at).to(eq(moment))
    }
  }

  context('hashid') {
    it('works with hashid') {
      poll = create_poll
      expect(Models::Poll.with_hashid(poll.hashid)).to(eq(poll))
    }
  }
}
