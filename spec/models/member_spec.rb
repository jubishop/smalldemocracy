require_relative '../../lib/models/group'

# TODO: Test add_response

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
      group = create_group
      member = group.add_member
      poll = group.add_poll(expiration: Time.now + 10)
      choice = poll.add_choice
      response = choice.add_response(member_id: member.id)
      expect(poll.responses).to(match_array(response))
      expect(choice.responses).to(match_array(response))
      member.destroy
      expect(choice.responses(reload: true)).to(be_empty)
      expect(poll.responses(reload: true)).to(be_empty)
    }
  }
}
