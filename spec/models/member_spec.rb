require_relative '../../lib/models/group'

# TODO: Test add_response
# TODO: Test add_poll

RSpec.describe(Models::Member) {
  context('delete or destroy') {
    it('will not allow removal of creator from group') {
      group = create_group
      expect { group.creating_member.destroy }.to(
          raise_error(Sequel::HookFailed))
    }

    it('will allow removal of a normal member') {
      group = create_group
      member = group.add_member
      expect { member.destroy }.to_not(raise_error)
    }

    it('will remove any responses upon destroy') {
      member = create_member
      poll = member.add_poll(expiration: Time.now + 10)
      choice = poll.add_choice
      response = member.add_response(choice_id: choice.id)
      expect(poll.responses).to(match_array(response))
      expect(choice.responses).to(match_array(response))
      member.destroy
      expect(choice.responses(reload: true)).to(be_empty)
      expect(poll.responses(reload: true)).to(be_empty)
    }
  }

  context('add_response') {
    it('will not allow adding a response to an expired poll') {
      member = create_member
      choice = member.add_poll(expiration: Time.now - 10).add_choice
      expect { member.add_response(choice_id: choice.id) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects adding a response without a choice') {
      member = create_member
      expect { member.add_response({}) }.to(raise_error(Sequel::HookFailed))
    }
  }
}
