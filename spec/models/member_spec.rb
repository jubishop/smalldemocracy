require_relative '../../lib/models/group'

RSpec.describe(Models::Member) {
  context('create') {
    it('creates a member') {
      member = create_member(email: 'me@email')
      expect(member.email).to(eq('me@email'))
    }

    it('rejects creating member with no email') {
      expect { create_member(email: nil) }.to(
          raise_error(Sequel::HookFailed, 'User created with no email'))
    }

    it('rejects creating member with empty email') {
      expect { create_member(email: '') }.to(
          raise_error(Sequel::HookFailed, 'User created with empty email'))
    }

    it('rejects creating member with invalid email') {
      expect { create_member(email: 'invalid@') }.to(
          raise_error(Sequel::HookFailed,
                      "User created with invalid email: 'invalid@'"))
    }
  }

  context('destroy') {
    it('rejects destroying creating member from group') {
      expect { create_member.destroy }.to(
          raise_error(Sequel::HookFailed,
                      /Creators.+cannot be removed from their group/))
    }

    it('destroys any responses') {
      member = create_group.add_member
      poll = member.add_poll(expiration: Time.now + 10)
      member.add_response(choice_id: poll.add_choice.id)
      expect(member.responses).to_not(be_empty)
      member.destroy
      expect(member.responses(reload: true)).to(be_empty)
    }
  }

  context('add_response') {
    it('adds a response to a member') {
      member = create_member
      choice = member.add_poll(expiration: Time.now + 10).add_choice
      response = member.add_response(choice_id: choice.id)
      expect(member.responses).to(match_array(response))
    }

    it('rejects adding a response to an expired poll') {
      member = create_member
      choice = member.add_poll(expiration: Time.now - 10).add_choice
      expect { member.add_response(choice_id: choice.id) }.to(
          raise_error(Sequel::HookFailed,
                      'Response created for expired poll'))
    }

    it('rejects adding a response without a choice') {
      member = create_member
      expect { member.add_response({}) }.to(
          raise_error(Sequel::HookFailed,
                      'Response created with no choice'))
    }
  }

  context('add_poll') {
    it('adds a poll to a member') {
      member = create_member
      poll = member.add_poll
      expect(member.polls).to(match_array(poll))
    }
  }

  context('polls') {
    before(:all) {
      @member = create_member
      @expired_poll = @member.add_poll(expiration: Time.now - 10)
      @my_poll = @member.add_poll(expiration: Time.now + 10)
    }

    it('finds all active polls with start_expiration') {
      expect(@member.polls(start_expiration: Time.now)).to(
          match_array(@my_poll))
    }

    it('finds all expired by polls with end_expiration') {
      expect(@member.polls(end_expiration: Time.now)).to(
          match_array(@expired_poll))
    }

    it('finds all polls') {
      expect(@member.polls).to(match_array([@my_poll, @expired_poll]))
    }
  }
}
