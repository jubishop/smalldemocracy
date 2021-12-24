require_relative '../../lib/models/user'

RSpec.describe(Models::User) {
  context('find_or_create') {
    it('creates a user') {
      user = create_user(email: 'me@email')
      expect(user.email).to(eq('me@email'))
    }

    it('creates a user only once') {
      new_user = create_user
      existing_user = create_user(email: new_user.email)
      expect(existing_user).to(eq(new_user))
    }

    it('rejects creating user with no email') {
      expect { create_user(email: nil) }.to(
          raise_error(Sequel::HookFailed, 'User created with no email'))
    }

    it('rejects creating user with empty email') {
      expect { create_user(email: '') }.to(
          raise_error(Sequel::HookFailed, 'User created with empty email'))
    }

    it('rejects creating user with invalid email') {
      expect { create_user(email: 'invalid@') }.to(
          raise_error(Sequel::HookFailed, "Email: 'invalid@', is invalid"))
    }
  }

  context('delete') {
    it('rejects deleting users') {
      user = create_user
      expect { user.delete }.to(
          raise_error(NoMethodError, /undefined method `delete'/))
    }
  }

  context('destroy') {
    it('rejects destroying users') {
      user = create_user
      expect { user.destroy }.to(
          raise_error(Sequel::HookFailed, 'Users cannot be destroyed'))
    }
  }

  context('members') {
    it('finds all members from any group') {
      user = create_user
      group = user.add_group
      member = create_group.add_member(email: user.email)
      expect(user.members).to(match_array([group.creating_member] + [member]))
    }
  }

  context('created_groups') {
    it('finds all groups it created') {
      user = create_user
      group = user.add_group
      expect(user.created_groups).to(match_array(group))
    }
  }

  context('created_polls') {
    it('finds all created polls from any group') {
      user = create_user
      my_poll = user.add_group.add_poll(email: user.email)
      other_group = create_group
      other_group.add_member(email: user.email)
      other_poll = other_group.add_poll(email: user.email)
      expect(user.created_polls).to(match_array([my_poll, other_poll]))
    }
  }

  context('groups') {
    it('finds all groups it is in from any creator') {
      user = create_user
      my_group = user.add_group
      other_group = create_group
      other_group.add_member(email: user.email)
      expect(user.groups).to(match_array([my_group, other_group]))
    }
  }

  context('polls') {
    before(:all) {
      @user = create_user
      my_group = @user.add_group
      other_group = create_group
      other_group.add_member(email: @user.email)
      @expired_poll = my_group.add_poll(expiration: Time.now - 10)
      @my_poll = my_group.add_poll(expiration: Time.now + 10)
      @other_poll = other_group.add_poll(expiration: Time.now + 10)
      @expired_other_poll = other_group.add_poll(expiration: Time.now - 10)
    }

    it('finds all active polls with start_expiration') {
      expect(@user.polls(start_expiration: Time.now)).to(
          match_array([@my_poll, @other_poll]))
    }

    it('finds all expired by polls with end_expiration') {
      expect(@user.polls(end_expiration: Time.now)).to(
          match_array([@expired_poll, @expired_other_poll]))
    }

    it('finds all polls') {
      expect(@user.polls).to(match_array([
                                           @my_poll,
                                           @other_poll,
                                           @expired_poll,
                                           @expired_other_poll
                                         ]))
    }
  }

  context('add_poll') {
    it('adds a poll to a user') {
      user = create_user
      poll = user.add_group.add_poll
      expect(user.created_polls).to(match_array(poll))
    }

    it('rejects creating a poll with no group') {
      user = create_user
      expect { user.add_poll }.to(
          raise_error(Sequel::HookFailed, 'Poll created with no group'))
    }
  }

  context('add_group') {
    it('adds a group to a user') {
      user = create_user
      group = user.add_group
      expect(user.created_groups).to(match_array(group))
    }

    it('always adds itself as a member to any group') {
      user = create_user
      group = user.add_group
      expect(group.members.map(&:email)).to(match_array(group.creator.email))
    }

    it('rejects adding duplicate groups') {
      user = create_user
      user.add_group(name: 'duplicate_name')
      expect { user.add_group(name: 'duplicate_name') }.to(
          raise_error(Sequel::UniqueConstraintViolation,
                      /Key \(name, email\).+already exists/))
    }
  }
}
