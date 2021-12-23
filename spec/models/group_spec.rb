require_relative '../../lib/models/group'

RSpec.describe(Models::Group) {
  context('delete or destroy') {
    it('will cascade destroy to members') {
      group = create_group
      group.add_member
      group_id = group.id
      expect(Models::Member.where(group_id: group_id).all).to_not(be_empty)
      group.destroy
      expect(Models::Member.where(group_id: group_id).all).to(be_empty)
    }

    it('will cascade destroy to polls') {
      group = create_group
      group.add_poll
      group_id = group.id
      expect(Models::Poll.where(group_id: group_id).all).to_not(be_empty)
      group.destroy
      expect(Models::Member.where(group_id: group_id).all).to(be_empty)
    }
  }

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
      member_one = group.add_member
      member_two = group.add_member
      expect(group.members).to(include(member_one, member_two))
    }

    it('throws error if adding member has no email') {
      group = create_group
      expect { group.add_member(email: nil) }.to(
          raise_error(Sequel::HookFailed))
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

    it('defaults to creating a poll that is `borda_single` type') {
      group = create_group
      poll = group.add_poll
      expect(poll.type).to(eq(:borda_single))
    }

    it('can create polls with other valid types') {
      group = create_group
      poll = group.add_poll(type: :borda_split)
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creation of polls of invalid type') {
      group = create_group
      expect { group.add_poll(type: :not_valid_type) }.to(
          raise_error(Sequel::DatabaseError))
    }
  }

  context('member') {
    it('finds a member properly') {
      group = create_group
      member = group.add_member
      expect(group.member(email: member.email)).to(eq(member))
    }
  }

  context('creating_member') {
    it('finds creating member properly') {
      user = create_user
      group = user.add_group
      expect(group.creating_member.email).to(eq(user.email))
    }
  }

  context('creator') {
    it('finds creator properly') {
      user = create_user
      group = user.add_group
      expect(group.creator).to(eq(user))
    }
  }

  context('#url') {
    it('creates url') {
      group = create_group
      expect(group.url).to(eq("/group/view/#{group.id}"))
    }
  }
}
