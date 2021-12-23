require_relative '../../lib/models/group'

RSpec.describe(Models::Member) {
  context('delete or destroy') {
    it('will not allow removal of creator from group') {
      group = create_group
      member = group.members.first
      expect { member.destroy }.to(raise_error(Sequel::HookFailed))
    }
  }
}
