require 'duration'

require_relative '../../lib/models/poll'

RSpec.describe(Models::Poll, type: :model) {
  context('.create') {
    it('creates a poll') {
      moment = future
      poll = create_poll(email: email,
                         title: 'title',
                         question: 'question',
                         expiration: moment,
                         type: :borda_split)
      expect(poll.email).to(eq(email))
      expect(poll.title).to(eq('title'))
      expect(poll.question).to(eq('question'))
      expect(poll.expiration).to(eq(moment))
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creating a poll where creator is not a member of group') {
      user = create_user
      group = create_group
      expect { create_poll(email: user.email, group_id: group.id) }.to(
          raise_error(Sequel::HookFailed,
                      "Creator #{user.email} is not a member of #{group.name}"))
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
          raise_error(Sequel::HookFailed, 'Expiration value is invalid'))
    }

    it('rejects creating a poll that is already expired') {
      expect { create_poll(expiration: past) }.to(
          raise_error(Sequel::HookFailed,
                      'Poll expiration set to time in the past'))
    }

    it('rejects creating polls with no type') {
      expect { create_poll(type: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "type"/))
    }

    it('rejects creating polls of invalid type') {
      expect { create_poll(type: :not_valid_type) }.to(
          raise_error(Sequel::DatabaseError,
                      /invalid input value for enum poll_type/))
    }
  }

  context('#destroy') {
    it('destroys itself from group') {
      group = create_group
      poll = group.add_poll
      expect(group.polls).to_not(be_empty)
      expect(poll.exists?).to(be(true))
      group.remove_poll(poll)
      expect(group.polls).to(be_empty)
      expect(poll.exists?).to(be(false))
    }

    it('destroys itself from user') {
      user = create_user
      poll = user.add_poll(group_id: user.add_group.id)
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

  context('#update') {
    it('rejects updating poll to expired time') {
      poll = create_poll
      expect { poll.update(expiration: past) }.to(
          raise_error(Sequel::HookFailed,
                      'Poll expiration set to time in the past'))
    }

    it('rejects updating poll to expiration time more than 90 days out') {
      poll = create_poll
      expect { poll.update(expiration: Time.now + 91.days) }.to(
          raise_error(Sequel::HookFailed,
                      'Poll expiration set to more than 90 days in the future'))
    }

    it('rejects updating poll type') {
      poll = create_poll
      expect { poll.update(type: :borda_split) }.to(
          raise_error(Sequel::HookFailed, 'Poll type is immutable'))
    }

    it('rejects updating title if poll has responses') {
      poll = create_poll
      poll.add_choice.add_response(member_id: poll.creating_member.id)
      expect { poll.update(title: 'title') }.to(
          raise_error(Sequel::HookFailed, 'Poll already has responses'))
    }

    it('rejects updating question if poll has responses') {
      poll = create_poll
      poll.add_choice.add_response(member_id: poll.creating_member.id)
      expect { poll.update(question: 'question') }.to(
          raise_error(Sequel::HookFailed, 'Poll already has responses'))
    }
  }

  context('#creator') {
    it('finds its creator') {
      user = create_user
      group = user.add_group
      poll = group.add_poll(email: user.email)
      expect(poll.creator).to(eq(user))
    }
  }

  context('#group') {
    it('finds its group') {
      group = create_group
      poll = group.add_poll
      expect(poll.group).to(eq(group))
    }
  }

  context('#choices') {
    it('finds its choices') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choices).to(match_array(choice))
    }
  }

  context('#responses') {
    it('finds all responses through join table') {
      poll = create_poll
      choice_one = poll.add_choice
      choice_two = poll.add_choice
      response_one = choice_one.add_response
      response_two = choice_two.add_response
      expect(poll.responses).to(match_array([response_one, response_two]))
    }
  }

  context(:timestamps) {
    it('sets updated_at and created_at upon creation') {
      poll = create_poll
      expect(poll.created_at).to(eq(Time.now))
      expect(poll.updated_at).to(eq(Time.now))
    }

    it('sets updated_at upon update to new value') {
      created_time = Time.now
      poll = create_poll
      updated_time = freeze_time(future)
      poll.update(title: 'title')
      expect(poll.created_at).to(eq(created_time))
      expect(poll.created_at).to_not(eq(poll.updated_at))
      expect(poll.updated_at).to(eq(updated_time))
    }
  }

  context('#hashid') {
    it('works with hashid') {
      poll = create_poll
      expect(Models::Poll.with_hashid(poll.hashid)).to(eq(poll))
    }
  }

  context('#members') {
    it('finds members from its group') {
      group = create_group
      group.add_member
      poll = group.add_poll
      expect(poll.members).to(match_array(group.members))
    }
  }

  context('#member') {
    it('finds a member from its group') {
      group = create_group
      member = group.add_member
      poll = group.add_poll
      expect(poll.member(email: member.email)).to(eq(member))
    }
  }

  context('#creating_member') {
    it('finds its creating member') {
      group = create_group
      member = group.add_member
      poll = group.add_poll(email: member.email)
      expect(poll.creating_member).to(eq(member))
    }
  }

  context('#choice') {
    it('finds a choice') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choice(text: choice.text)).to(eq(choice))
    }

    it('returns nil when choice does not exist') {
      poll = create_poll
      expect(poll.choice(text: 'does not exist')).to(be_nil)
    }
  }

  context('#finished?') {
    it('returns an open poll as unfinished') {
      poll = create_poll
      expect(poll.finished?).to(be(false))
    }

    it('returns an expired poll as finished') {
      poll = create_poll
      freeze_time(future + 1.day)
      expect(poll.finished?).to(be(true))
    }
  }

  context('#any_response?') {
    it('returns false when no responses given') {
      poll = create_poll
      expect(poll.any_response?).to(be(false))
    }

    it('returns false when a response has been given but then destroyed') {
      poll = create_poll
      choice = poll.add_choice
      response = choice.add_response(member_id: poll.creating_member.id)
      response.destroy
      expect(poll.any_response?).to(be(false))
    }

    it('returns true when a response has been given') {
      poll = create_poll
      choice = poll.add_choice
      choice.add_response(member_id: poll.creating_member.id)
      expect(poll.any_response?).to(be(true))
    }
  }

  context('#responses') {
    it('returns responses from a specific member or all responses') {
      group = create_group
      member = group.add_member
      other_member = group.add_member
      poll = group.add_poll
      choices = Array.new(10).fill { poll.add_choice }
      responses = choices.map { |choice|
        choice.add_response(member_id: member.id)
      }
      other_responses = choices.map { |choice|
        choice.add_response(member_id: other_member.id)
      }
      expect(poll.responses(member_id: member.id)).to(match_array(responses))
      expect(poll.responses(reload: true)).to(
          match_array(responses + other_responses))
    }
  }

  context('#remove_responses') {
    it('removes responses from a specific member') {
      member = create_member
      poll = member.group.add_poll
      choices = Array.new(10).fill { poll.add_choice }
      responses = choices.map { |choice|
        choice.add_response(member_id: member.id)
      }
      remaining_response = member.group.add_poll.add_choice.add_response
      expect(member.responses(poll_id: poll.id).length).to(eq(10))
      responses.each { |response| expect(response.exists?).to(be(true)) }
      poll.remove_responses(member_id: member.id)
      expect(member.responses(poll_id: poll.id)).to(be_empty)
      responses.each { |response| expect(response.exists?).to(be(false)) }
      expect(remaining_response.exists?).to(be(true))
    }
  }

  context(:results) {
    it('raises error if using scores on choose_* types') {
      poll = create_poll(type: :choose_one)
      freeze_time(future + 1.day)
      expect { poll.scores }.to(
          raise_error(TypeError, /must be one of borda_single or borda_split/))
    }

    it('raises an error if using counts on borda_single type') {
      poll = create_poll(type: :borda_single)
      freeze_time(future + 1.day)
      expect { poll.counts }.to(
          raise_error(TypeError, /must be one of borda_split or choose_one/))
    }

    shared_examples('#scores') {
      it('computes scores properly') {
        @poll.expiration = past
        results = @expected_results.transform_values { |v| v.values.sum }
        results = results.sort_by { |_, v| -v }
        expect(@poll.scores.map(&:to_s)).to(
            match_array(results.map { |r| r[0].to_s }))
        expect(@poll.scores).to(match_array(results.map { |r| r[1] }))
      }

      it('rejects computing scores if unfinished') {
        @poll.expiration = future
        expect { @poll.scores }.to(
            raise_error(SecurityError, /is not finished/))
      }
    }

    shared_examples('#counts') {
      it('computes counts properly') {
        @poll.expiration = past
        results = @expected_results.transform_values(&:length).sort_by { |k, v|
          [-v, -@expected_results[k].values.sum(&:to_i)]
        }
        expect(@poll.counts.map(&:to_s)).to(
            match_array(results.map { |r| r[0].to_s }))
        expect(@poll.counts.map(&:to_i)).to(
            match_array(results.map { |r| r[1] }))
      }

      it('rejects computing counts if unfinished') {
        @poll.expiration = future
        expect { @poll.counts }.to(
            raise_error(SecurityError, /is not finished/))
      }
    }

    shared_examples('#breakdown') {
      it('computes breakdown properly') {
        @poll.expiration = past
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

      it('rejects computing breakdown if unfinished') {
        @poll.expiration = future
        expect { @poll.breakdown }.to(
            raise_error(SecurityError, /is not finished/))
      }
    }

    context(':borda_single') {
      before(:all) {
        choices = %w[one two three four five six]
        members = %w[a@a b@b c@c d@d e@e f@f]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(type: :borda_single)
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
            member.add_response(choice_id: choice.id, data: { score: score })
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

        # Random other polls that should affect nothing.
        borda_split_poll = group.add_poll(type: :borda_split)
        borda_split_choice = borda_split_poll.add_choice(
            text: 'borda split choice')
        borda_split_poll.member(email: 'f@f').add_response(
            choice_id: borda_split_choice.id, data: { score: 1 })
        choose_one_poll = group.add_poll(type: :choose_one)
        choose_one_choice = choose_one_poll.add_choice(
            text: 'choose one choice')
        group.creating_member.add_response(choice_id: choose_one_choice.id)
      }

      it_has_behavior('#breakdown')
      it_has_behavior('#scores')
    }

    context(':borda_split') {
      before(:all) {
        choices = %w[one two three four five six]
        members = %w[a@a b@b c@c d@d e@e f@f]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(type: :borda_split)
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
              member.add_response(choice_id: choice.id, data: { score: score })
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

        # Random other polls that should affect nothing.
        borda_single_poll = group.add_poll(type: :borda_single)
        borda_single_choice = borda_single_poll.add_choice(
            text: 'borda single choice')
        borda_single_poll.member(email: 'f@f').add_response(
            choice_id: borda_single_choice.id, data: { score: 1 })
        choose_one_poll = group.add_poll(type: :choose_one)
        choose_one_choice = choose_one_poll.add_choice(
            text: 'choose one choice')
        group.creating_member.add_response(choice_id: choose_one_choice.id)
      }

      it_has_behavior('#breakdown')
      it_has_behavior('#scores')
      it_has_behavior('#counts')
    }

    context(':choose_one') {
      before(:all) {
        choices = %w[yes no maybe]
        members = %w[a@a b@b c@c d@d e@e f@f g@g]

        group = create_group
        members.each { |member| group.add_member(email: member) }

        @poll = group.add_poll(type: :choose_one)
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

        # Random other polls that should affect nothing.
        borda_single_poll = group.add_poll(type: :borda_single)
        borda_single_choice = borda_single_poll.add_choice(
            text: 'borda single choice')
        borda_single_poll.member(email: 'f@f').add_response(
            choice_id: borda_single_choice.id, data: { score: 1 })
        # Random other polls that should affect nothing.
        borda_split_poll = group.add_poll(type: :borda_split)
        borda_split_choice = borda_split_poll.add_choice(
            text: 'borda split choice')
        borda_split_poll.member(email: 'f@f').add_response(
            choice_id: borda_split_choice.id, data: { score: 1 })
      }

      it_has_behavior('#breakdown')
      it_has_behavior('#counts')
    }
  }

  context('#url') {
    it('creates url for viewing') {
      poll = create_poll
      expect(poll.url).to(eq("/poll/view/#{poll.hashid}"))
    }
  }

  context('#edit_url') {
    it('creates url for editing') {
      poll = create_poll
      expect(poll.edit_url).to(eq("/poll/edit/#{poll.hashid}"))
    }
  }

  context('#duplicate_url') {
    it('creates url for duplicating') {
      poll = create_poll
      expect(poll.duplicate_url).to(eq("/poll/create?from=#{poll.hashid}"))
    }
  }

  context('#add_choice') {
    it('adds a choice') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choices).to(match_array(choice))
    }

    it('rejects adding a choice to a poll with responses') {
      poll = create_poll
      poll.add_choice.add_response(member_id: poll.creating_member.id)
      expect { poll.add_choice }.to(
          raise_error(Sequel::HookFailed,
                      'Choice modified in poll with responses'))
    }

    it('rejects creating two choices with the same text') {
      poll = create_poll
      poll.add_choice(text: 'one')
      expect { poll.add_choice(text: 'one') }.to(
          raise_error(Sequel::ConstraintViolation,
                      /violates unique constraint "choice_unique"/))
    }
  }
}
