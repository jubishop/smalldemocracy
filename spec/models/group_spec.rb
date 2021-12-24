require_relative '../../lib/models/group'

RSpec.describe(Models::Group) {
  context('delete or destroy') {
    it('will cascade destroy to members') {
      group = create_group
      member = group.add_member
      expect(group.members).to(include(member))
      group.destroy
      expect(group.members(reload: true)).to(be_empty)
    }

    it('will cascade destroy to polls') {
      group = create_group
      poll = group.add_poll
      expect(group.polls).to(include(poll))
      group.destroy
      expect(group.polls(reload: true)).to(be_empty)
    }
  }

  context('add_member') {
    it('can add an existing user as a member to a group') {
      group = create_group
      user = create_user
      member = group.add_member(email: user.email)
      expect(member.user).to(eq(user))
      expect(group.members).to(include(member))
    }

    it('can add a new user as a member to a group') {
      group = create_group
      member = group.add_member
      expect(member.user).to(eq(Models::User.find(email: member.email)))
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

    it('refuses to create a poll where member is not in group') {
      group = create_group
      user = create_user
      expect { group.add_poll(email: user.email) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creating a poll with no email') {
      group = create_group
      expect { group.add_poll(email: nil) }.to(raise_error(Sequel::HookFailed))
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
