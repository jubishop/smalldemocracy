require_relative '../../lib/models/user'

RSpec.describe(Models::User) {
  context('find_or_create') {
    it('creates a user') {
      new_user = create_user(email: 'a@a')
      expect(new_user.email).to(eq('a@a'))

      existing_user = create_user(email: 'a@a')
      expect(existing_user).to(eq(new_user))
    }

    it('throws error if user has no email') {
      expect { create_user(email: nil) }.to(raise_error(Sequel::HookFailed))
    }

    it('throws error if user has empty email') {
      expect { create_user(email: '') }.to(raise_error(Sequel::HookFailed))
    }

    it('throws error if user has invalid email') {
      expect {
        create_user(email: 'invalid@')
      }.to(raise_error(Sequel::HookFailed))
    }
  }

  context('delete or destroy') {
    it('will not allow users to be deleted') {
      user = create_user
      expect { user.delete }.to(raise_error(NoMethodError))
    }

    it('will not allow users to be destroyed') {
      user = create_user
      expect { user.destroy }.to(raise_error(Sequel::HookFailed))
    }
  }

  context('polls') {
    it('finds all active polls') {
      user = create_user(email: 'me@me')
      other_user = create_user
      my_group = user.add_group(name: 'my_group')
      other_group = other_user.add_group(name: 'other_group')
      other_group.add_member(email: 'me@me')
      unrelated_group = other_user.add_group(name: 'unrelated_group')
      unrelated_group.add_poll(title: 'title',
                               question: 'question',
                               expiration: Time.now + 10)
      my_group.add_poll(expiration: Time.now - 10)
      my_poll = my_group.add_poll(expiration: Time.now + 10)
      other_poll = other_group.add_poll(expiration: Time.now + 10)
      expect(user.polls).to(match_array([my_poll, other_poll]))
    }
  }

  context('add_group') {
    it('throws error if group has no name') {
      expect {
        create_group(name: nil)
      }.to(raise_error(Sequel::NotNullConstraintViolation))
    }

    it('throws error if group has empty name') {
      expect {
        create_group(name: '')
      }.to(raise_error(Sequel::CheckConstraintViolation))
    }

    it('can add a group and become the creator') {
      user = create_user
      group = user.add_group(name: 'creator_group')
      expect(group.creator).to(eq(user))
    }

    it('always adds itself as a member to any group') {
      user = create_user
      group = user.add_group(name: 'name')
      expect(group.members.length).to(be(1))
      expect(group.members[0].email).to(eq(group.creator.email))
    }

    it('will not allow removal of creator from group') {
      user = create_user
      group = user.add_group(name: 'name')
      member = group.members.first
      expect { member.destroy }.to(raise_error(Sequel::HookFailed))
    }

    it('throws error if adding duplicate groups') {
      user = create_user
      user.add_group(name: 'duplicate_name')
      expect {
        user.add_group(name: 'duplicate_name')
      }.to(raise_error(Sequel::UniqueConstraintViolation))
    }
  }
}
