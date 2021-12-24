require_relative '../../lib/models/group'

# TODO: Test add_response
# TODO: Test add_poll

RSpec.describe(Models::Member) {
  context('destroy') {
    it('rejects destroying creating member from group') {
      expect { create_group.creating_member.destroy }.to(
          raise_error(Sequel::HookFailed))
    }

    it('destroys any responses') {
      member = create_member
      poll = member.add_poll(expiration: Time.now + 10)
      response = member.add_response(choice_id: poll.add_choice.id)
      expect(poll.responses).to(match_array(response))
      member.destroy
      expect(poll.responses(reload: true)).to(be_empty)
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
}
