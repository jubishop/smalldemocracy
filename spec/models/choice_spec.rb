require_relative '../../lib/models/choice'

RSpec.describe(Models::Choice) {
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

  # TODO: Test destroy removes all responses.
  # TODO: Test can't add response to finished poll.
}
