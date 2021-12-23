require_relative '../../lib/models/group'

RSpec.describe(Models::Group) {
  context('add_member') {
    it('can add an existing user as a member to a group') {
      group = create_group
      create_user(email: 'a@a')
      member = group.add_member(email: 'a@a')
      expect(member.user).to(eq(Models::User['a@a']))
      expect(group.members).to(include(member))
    }

    it('can add a new user as a member to a group') {
      group = create_group
      member = group.add_member(email: 'a@a')
      expect(member.user).to(eq(Models::User['a@a']))
      expect(group.members).to(include(member))
    }

    it('can add multiple members to a group') {
      group = create_group
      member_one = group.add_member(email: 'a@a')
      member_two = group.add_member(email: 'b@b')
      expect(group.members).to(include(member_one, member_two))
    }

    it('throws error if adding member has no email') {
      group = create_group
      expect { group.add_member }.to(raise_error(ArgumentError))
    }

    it('throws error if adding member has empty email') {
      group = create_group
      expect { group.add_member(email: '') }.to(raise_error(Sequel::HookFailed))
    }

    it('throws error if adding member has invalid email') {
      group = create_group
      expect {
        group.add_member(email: 'invalid@')
      }.to(raise_error(Sequel::HookFailed))
    }

    it('throws error if adding duplicate members') {
      group = create_group
      group.add_member(email: 'one@one')
      expect {
        group.add_member(email: 'one@one')
      }.to(raise_error(Sequel::UniqueConstraintViolation))
    }
  }

  context('add_poll') {
    it('can add a poll to a group') {
      group = create_group
      poll = group.add_poll
      expect(poll.group).to(eq(group))
    }

    it('matches members from poll to its group') {
      group = create_group
      group.add_member(email: 'b@b')
      poll = group.add_poll
      expect(poll.members).to(match_array(group.members))
    }
  }
}
