require_relative '../../lib/models/choice'

# TODO: Test can't remove a choice from expired poll.

RSpec.describe(Models::Choice) {
  context('delete or destroy') {
    it('will remove any responses upon destroy') {
      choice = create_choice(expiration: Time.now + 10)
      poll = choice.poll
      member = poll.group.add_member
      response = choice.add_response(member_id: member.id)
      expect(poll.responses).to(match_array(response))
      choice.destroy
      expect(poll.responses(reload: true)).to(be_empty)
    }
  }

  context('add_response') {
    it('will not allow adding a response to an expired poll') {
      choice = create_choice(expiration: Time.now - 10)
      member = choice.poll.group.add_member
      expect { choice.add_response(member_id: member.id) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects adding a response without a member') {
      choice = create_choice(expiration: Time.now + 10)
      expect { choice.add_response({}) }.to(
          raise_error(Sequel::NotNullConstraintViolation))
    }
  }

  # TODO: Can't remove choice after poll has expired.
}
