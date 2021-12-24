require_relative '../../lib/models/group'

RSpec.describe(Models::Group) {
  context('create') {
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
                      /violate.+"name_not_empty"/))
    }
  }

  context('destroy') {
    it('will cascade destroy to members') {
      group = create_group
      expect(group.members).to_not(be_empty)
      group.destroy
      expect(group.members(reload: true)).to(be_empty)
    }

    it('will cascade destroy to polls') {
      group = create_group
      group.add_poll
      expect(group.polls).to_not(be_empty)
      group.destroy
      expect(group.polls(reload: true)).to(be_empty)
    }
  }

  context('creator') {
    it('finds its creator') {
      user = create_user
      group = user.add_group
      expect(group.creator).to(eq(user))
    }
  }

  context('members') {
    it('finds all its members') {
      group = create_group
      member = group.add_member
      expect(group.members).to(match_array([group.creating_member, member]))
    }
  }

  context('polls') {
    it('finds all its polls') {
      group = create_group
      poll = group.add_poll
      expect(group.polls).to(match_array(poll))
    }
  }

  context('creating_member') {
    it('finds its creating member') {
      user = create_user
      group = user.add_group
      expect(group.creating_member.email).to(eq(user.email))
    }
  }

  context('member') {
    it('finds a member') {
      group = create_group
      member = group.add_member
      expect(group.member(email: member.email)).to(eq(member))
    }
  }

  context('#url') {
    it('creates url') {
      group = create_group
      expect(group.url).to(eq("/group/view/#{group.id}"))
    }
  }

  context('add_member') {
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
      group.add_member(email: 'dup@dup')
      expect { group.add_member(email: 'dup@dup') }.to(
          raise_error(Sequel::UniqueConstraintViolation,
                      /Key \(email, group_id\).+already exists/))
    }
  }

  context('add_poll') {
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
          raise_error(Sequel::HookFailed, 'Poll created with no creator'))
    }

    it('rejects creating a poll with empty creator email') {
      group = create_group
      expect { group.add_poll(email: '') }.to(
          raise_error(Sequel::HookFailed, 'Poll created with empty creator'))
    }

    it('rejects creating a poll with invalid creator email') {
      group = create_group
      expect { group.add_poll(email: 'invalid') }.to(
          raise_error(Sequel::HookFailed,
                      "Poll created with invalid creator email: 'invalid'"))
    }
  }
}
