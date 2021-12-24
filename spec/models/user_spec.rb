require_relative '../../lib/models/user'

RSpec.describe(Models::User) {
  context('find_or_create') {
    it('creates a user only once') {
      new_user = create_user
      existing_user = create_user(email: new_user.email)
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
    before(:all) {
      @user = create_user
      other_user = create_user
      my_group = @user.add_group
      other_group = other_user.add_group
      other_group.add_member(email: @user.email)
      unrelated_group = other_user.add_group
      unrelated_group.add_poll(expiration: Time.now + 10)
      unrelated_group.add_poll(expiration: Time.now - 10)
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

  context('groups') {
    it('finds all groups it owns') {
      user = create_user
      group = user.add_group
      expect(user.groups).to(match_array(group))
    }
  }

  context('members') {
    it('finds all members from any group') {
      user = create_user
      my_group = user.add_group
      other_group = create_group
      member = other_group.add_member(email: user.email)
      expect(user.members).to(match_array(my_group.members + [member]))
    }
  }

  context('created_polls') {
    it('finds all created polls from any group') {
      user = create_user
      other_group = create_group
      other_group.add_member(email: user.email)
      my_poll = user.add_group.add_poll(email: user.email)
      other_poll = other_group.add_poll(email: user.email)
      expect(user.created_polls).to(match_array([my_poll, other_poll]))
    }
  }

  context('add_poll') {
    it('can add a poll to a user') {
      user = create_user
      user.add_group
      poll = user.add_poll
      expect(user.created_polls).to(match_array(poll))
    }

    it('rejects creating a poll with no group') {
      user = create_user
      expect { user.add_poll(group_id: nil) }.to(
          raise_error(Sequel::HookFailed))
    }

    it('defaults to creating a poll that is `borda_single` type') {
      group = create_group
      poll = group.creator.add_poll
      expect(poll.type).to(eq(:borda_single))
    }

    it('can create polls with other valid types') {
      group = create_group
      poll = group.creator.add_poll(type: :borda_split)
      expect(poll.type).to(eq(:borda_split))
    }

    it('rejects creation of polls of invalid type') {
      group = create_group
      expect { group.creator.add_poll(type: :not_valid_type) }.to(
          raise_error(Sequel::DatabaseError))
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

    it('always adds itself as a member to any group') {
      user = create_user
      group = user.add_group
      expect(group.members.map(&:email)).to(match_array(group.creator.email))
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
