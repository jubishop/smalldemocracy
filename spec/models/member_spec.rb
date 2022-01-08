require_relative '../../lib/models/group'

RSpec.describe(Models::Member, type: :model) {
  context('.create') {
    it('creates a member') {
      member = create_member(email: email)
      expect(member.email).to(eq(email))
    }

    it('rejects creating member with no email') {
      expect { create_member(email: nil) }.to(
          raise_error(Sequel::HookFailed, 'User has no email'))
    }

    it('rejects creating member with empty email') {
      expect { create_member(email: '') }.to(
          raise_error(Sequel::HookFailed, 'User has empty email'))
    }

    it('rejects creating member with invalid email') {
      expect { create_member(email: 'invalid@') }.to(
          raise_error(Sequel::HookFailed,
                      "User has invalid email: 'invalid@'"))
    }
  }

  context('#destroy') {
    it('destroys itself from group') {
      group = create_group
      member = group.add_member
      expect(group.members).to(include(member))
      expect(member.exists?).to(be(true))
      group.remove_member(member)
      expect(group.members).to_not(include(member))
      expect(member.exists?).to(be(false))
    }

    it('rejects destroying creating member from group') {
      expect { create_member.destroy }.to(
          raise_error(Sequel::HookFailed,
                      /Creators.+cannot be removed from their group/))
    }

    it('cascades destroy to responses') {
      group = create_group
      member = group.add_member
      poll = group.add_poll
      response = member.add_response(choice_id: poll.add_choice.id)
      expect(poll.responses).to_not(be_empty)
      expect(response.exists?).to(be(true))
      member.destroy
      expect(poll.responses(reload: true)).to(be_empty)
      expect(response.exists?).to(be(false))
    }
  }

  context('#update') {
    it('rejects any updates') {
      member = create_member
      expect { member.update(email: email) }.to(
          raise_error(Sequel::HookFailed, 'Members are immutable'))
    }
  }

  context('#group') {
    it('finds its group') {
      group = create_group
      member = group.add_member
      expect(member.group).to(eq(group))
    }
  }

  context('#user') {
    it('finds its user') {
      user = create_user
      group = create_group
      member = group.add_member(email: user.email)
      expect(member.user).to(eq(user))
    }
  }

  context('#responded?') {
    it('reports not responding to a poll') {
      member = create_member
      poll = member.group.add_poll
      expect(member.responded?(poll_id: poll.id)).to(be(false))
    }

    it('reports responding to a poll') {
      member = create_member
      poll = member.group.add_poll
      member.add_response(choice_id: poll.add_choice.id)
      expect(member.responded?(poll_id: poll.id)).to(be(true))
    }
  }

  context('#responses') {
    let(:member) { create_member }
    let(:poll) { member.group.add_poll }
    let!(:response) { member.add_response(choice_id: poll.add_choice.id) }
    let(:other_response) {
      member.add_response(choice_id: member.group.add_poll.add_choice.id)
    }

    it('returns only responses for a specific poll when poll_id: passed') {
      expect(member.responses(poll_id: poll.id)).to(match_array(response))
    }

    it('returns all responses when poll_id: nil') {
      expect(member.responses).to(match_array([response, other_response]))
    }
  }

  context('#add_response') {
    it('adds a response to a member') {
      member = create_member
      choice = member.group.add_poll.add_choice
      response = member.add_response(choice_id: choice.id)
      expect(member.responses).to(match_array(response))
    }

    it('rejects adding a response to an expired poll') {
      member = create_member
      poll = member.group.add_poll
      choice = poll.add_choice
      poll.update(expiration: past)
      expect { member.add_response(choice_id: choice.id) }.to(
          raise_error(Sequel::HookFailed, 'Response modified in expired poll'))
    }

    it('rejects adding a response without a choice') {
      member = create_member
      expect { member.add_response(choice_id: nil) }.to(
          raise_error(Sequel::HookFailed, 'Response has no poll'))
    }

    it('rejects adding two responses to the same choice') {
      group = create_group
      member = group.add_member
      poll = group.add_poll
      choice = poll.add_choice
      member.add_response(choice_id: choice.id)
      expect { member.add_response(choice_id: choice.id) }.to(
          raise_error(Sequel::ConstraintViolation,
                      /violates unique constraint "response_unique"/))
    }
  }
}
