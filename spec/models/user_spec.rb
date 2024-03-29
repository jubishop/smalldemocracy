require 'duration'
require 'securerandom'

require_relative '../../lib/models/user'

RSpec.describe(Models::User, type: :model) {
  context('.find_or_create') {
    it('creates a user') {
      allow(SecureRandom).to(
          receive(:alphanumeric).with(24).and_return('abc123'))
      user = create_user(email: email)
      expect(user.email).to(eq(email))
      expect(user.api_key).to(eq('abc123'))
    }

    it('creates a user only once') {
      new_user = create_user
      existing_user = create_user(email: new_user.email)
      expect(existing_user).to(eq(new_user))
    }

    it('rejects creating user with no email') {
      expect { create_user(email: nil) }.to(
          raise_error(Sequel::HookFailed, 'User has no email'))
    }

    it('rejects creating user with empty email') {
      expect { create_user(email: '') }.to(
          raise_error(Sequel::HookFailed, 'User has empty email'))
    }

    it('rejects creating user with invalid email') {
      expect { create_user(email: 'invalid@') }.to(
          raise_error(Sequel::HookFailed, 'User has invalid email invalid@'))
    }
  }

  context('find(api_key:)') {
    it('finds a user by api_key') {
      user = create_user(email: email)
      api_user = Models::User.find(api_key: user.api_key)
      expect(api_user).to(eq(user))
    }
  }

  context('#delete') {
    it('rejects deleting users') {
      user = create_user
      expect { user.delete }.to(
          raise_error(NoMethodError, /undefined method `delete'/))
    }
  }

  context('#destroy') {
    it('rejects destroying users') {
      user = create_user
      expect { user.destroy }.to(
          raise_error(Sequel::HookFailed, 'Users cannot be destroyed'))
    }
  }

  context('#update') {
    it('rejects any updates to email') {
      user = create_user
      expect { user.update(email: random_email) }.to(
          raise_error(Sequel::HookFailed, 'User emails are immutable'))
    }

    it('allows updates to api_key') {
      user = create_user
      new_key = Models::User.create_api_key
      user.update(api_key: new_key)
      expect(user.api_key).to(eq(new_key))
    }

    it('rejects updating user with invalid api_key') {
      user = create_user
      new_key = 'bad_key'
      expect { user.update(api_key: new_key) }.to(
          raise_error(Sequel::HookFailed,
                      'User api_keys must be 24 characters'))
    }
  }

  context('#members') {
    it('finds all members from any group') {
      user = create_user
      group = user.add_group
      member = create_group.add_member(email: user.email)
      expect(user.members).to(match_array([group.creating_member] + [member]))
    }
  }

  context('#created_groups') {
    it('finds all groups it created') {
      user = create_user
      group = user.add_group
      expect(user.created_groups).to(match_array(group))
    }
  }

  context('#created_polls') {
    it('finds all created polls from any group') {
      user = create_user
      my_poll = user.add_group.add_poll(email: user.email)
      other_group = create_group
      other_group.add_member(email: user.email)
      other_poll = other_group.add_poll(email: user.email)
      expect(user.created_polls).to(match_array([my_poll, other_poll]))
    }
  }

  context('#groups') {
    it('finds all groups it is in from any creator') {
      user = create_user
      my_group = user.add_group
      other_group = create_group
      other_group.add_member(email: user.email)
      expect(user.groups).to(match_array([my_group, other_group]))
    }
  }

  context('#polls') {
    before(:context) {
      @current_time = future + 15.seconds
      @user = create_user
      my_group = @user.add_group
      other_group = create_group
      other_group.add_member(email: @user.email)
      @expired_poll = my_group.add_poll(expiration: @current_time - 10.seconds)
      @expired_other_poll = other_group.add_poll(
          expiration: @current_time - 5.seconds)
      @my_poll = my_group.add_poll(expiration: @current_time + 5.seconds)
      @other_poll = other_group.add_poll(expiration: @current_time + 10.seconds)
    }

    before(:each) {
      freeze_time(@current_time)
    }

    it('finds all active polls with start_expiration sorted ascending') {
      expect(@user.polls(start_expiration: Time.now)).to(
          eq([@my_poll, @other_poll]))
    }

    it('finds all active polls with start_expiration sorted descending') {
      expect(@user.polls(start_expiration: Time.now, order: :desc)).to(
          eq([@other_poll, @my_poll]))
    }

    it('finds all expired by polls with end_expiration sorted ascending') {
      expect(@user.polls(end_expiration: Time.now)).to(
          eq([@expired_poll, @expired_other_poll]))
    }

    it('finds all expired by polls with end_expiration sorted descending') {
      expect(@user.polls(end_expiration: Time.now, order: :desc)).to(
          eq([@expired_other_poll, @expired_poll]))
    }

    it('finds all polls sorted ascending') {
      expect(@user.polls).to(
          eq([@expired_poll, @expired_other_poll, @my_poll, @other_poll]))
    }

    it('finds all polls sorted descending') {
      expect(@user.polls(order: :desc)).to(
          eq([@other_poll, @my_poll, @expired_other_poll, @expired_poll]))
    }

    it('finds polls up to a limit sorted ascending') {
      expect(@user.polls(limit: 2)).to(eq([@expired_poll, @expired_other_poll]))
    }

    it('finds polls up to a limit sorted descending') {
      expect(@user.polls(limit: 2, order: :desc)).to(
          eq([@other_poll, @my_poll]))
    }
  }

  context('#add_member') {
    it('rejects adding members directly from user') {
      user = create_user
      expect { user.add_member }.to(
          raise_error(NoMethodError, /undefined method `add_member'/))
    }
  }

  context('#add_poll') {
    it('adds a poll to a user') {
      user = create_user
      poll = user.add_group.add_poll
      expect(user.created_polls).to(match_array(poll))
    }

    it('rejects creating a poll with no group') {
      user = create_user
      expect { user.add_poll }.to(
          raise_error(Sequel::HookFailed, 'Poll has no group'))
    }
  }

  context('#add_group') {
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
