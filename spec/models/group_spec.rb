require_relative '../../lib/models/group'

RSpec.describe(Models::Group, type: :model) {
  context('.create') {
    it('creates a group') {
      group = create_group(name: 'group_name')
      expect(group.name).to(eq('group_name'))
    }

    it('rejects creating group with no name') {
      expect { create_group(name: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "name"/))
    }

    it('rejects creating group with empty name') {
      expect { create_group(name: '') }.to(
          raise_error(Sequel::CheckConstraintViolation,
                      /violates check constraint "name_not_empty"/))
    }
  }

  context('#destroy') {
    it('destroys itself from user') {
      user = create_user
      group = user.add_group
      expect(user.groups).to_not(be_empty)
      expect(user.created_groups).to_not(be_empty)
      expect(group.exists?).to(be(true))
      user.remove_group(group)
      expect(user.groups).to(be_empty)
      expect(user.created_groups).to(be_empty)
      expect(group.exists?).to(be(false))
    }

    it('cascades destroy to members') {
      user = create_user
      group = user.add_group
      member = group.add_member
      expect(user.members).to_not(be_empty)
      expect(member.exists?).to(be(true))
      group.destroy
      expect(user.members(reload: true)).to(be_empty)
      expect(member.exists?).to(be(false))
    }

    it('cascades destroy to polls') {
      user = create_user
      group = user.add_group
      poll = group.add_poll
      expect(user.polls).to_not(be_empty)
      expect(poll.exists?).to(be(true))
      group.destroy
      expect(user.polls).to(be_empty)
      expect(poll.exists?).to(be(false))
    }
  }

  context('#creator') {
    it('finds its creator') {
      user = create_user
      group = user.add_group
      expect(group.creator).to(eq(user))
    }
  }

  context('#members') {
    it('finds all its members') {
      group = create_group
      member = group.add_member
      expect(group.members).to(match_array([group.creating_member, member]))
    }
  }

  context('#polls') {
    it('finds all its polls') {
      group = create_group
      poll = group.add_poll
      expect(group.polls).to(match_array(poll))
    }
  }

  context('#hashid') {
    it('works with hashid') {
      group = create_group
      expect(Models::Group.with_hashid(group.hashid)).to(eq(group))
    }
  }

  context('#creating_member') {
    it('finds its creating member') {
      user = create_user
      group = user.add_group
      expect(group.creating_member.email).to(eq(user.email))
    }
  }

  context('#member') {
    it('finds a member') {
      group = create_group
      member = group.add_member
      expect(group.member(email: member.email)).to(eq(member))
    }
  }

  context('#url') {
    it('creates url') {
      group = create_group
      expect(group.url).to(eq("/group/view/#{group.hashid}"))
    }
  }

  context('#add_member') {
    it('adds an existing user as a member to a group') {
      group = create_group
      member = group.add_member(email: create_user.email)
      expect(group.members).to(match_array([group.creating_member, member]))
    }

    it('creates a new user when adding member to a group') {
      group = create_group
      member = group.add_member
      expect(member.user.email).to(eq(member.email))
      expect(group.members).to(match_array([group.creating_member, member]))
    }

    it('rejects adding duplicate members') {
      group = create_group
      group.add_member(email: email)
      expect { group.add_member(email: email) }.to(
          raise_error(Sequel::UniqueConstraintViolation,
                      /Key \(email, group_id\).+already exists/))
    }
  }

  context('#remove_member') {
    it('removes a member') {
      group = create_group
      member = group.add_member
      expect(member.user.email).to(eq(member.email))
      expect(group.members).to(match_array([group.creating_member, member]))
      group.remove_member(member)
      expect(group.members).to(match_array(group.creating_member))
    }
  }

  context('#add_poll') {
    it('adds a poll to a group') {
      group = create_group
      poll = group.add_poll
      expect(group.polls).to(match_array(poll))
    }

    it('rejects creating a poll where creator is not in group') {
      group = create_group
      other_user = create_user
      expect { group.add_poll(email: other_user.email) }.to(
          raise_error(Sequel::HookFailed, /Creator.+is not a member/))
    }

    it('rejects creating a poll with no creator email') {
      group = create_group
      expect { group.add_poll(email: nil) }.to(
          raise_error(Sequel::HookFailed, 'Poll has no email'))
    }

    it('rejects creating a poll with empty creator email') {
      group = create_group
      expect { group.add_poll(email: '') }.to(
          raise_error(Sequel::HookFailed, 'Poll has empty email'))
    }

    it('rejects creating a poll with invalid creator email') {
      group = create_group
      expect { group.add_poll(email: 'invalid') }.to(
          raise_error(Sequel::HookFailed, "Poll has invalid email: 'invalid'"))
    }
  }
}
