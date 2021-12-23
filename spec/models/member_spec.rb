require_relative '../../lib/models/group'

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
  }
}
