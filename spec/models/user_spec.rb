require_relative '../../lib/models/user'

RSpec.describe(Models::User) {
  def create_user(email: "#{rand}@a")
    return Models::User.find_or_create(email: email)
  end

  def create_group(email: 'a@a', name: rand.to_s)
    return create_user(email: email).add_group(name: name)
  end

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

    it('throws error if user has invalid email') {
      expect {
        create_user(email: 'invalid@')
      }.to(raise_error(Sequel::HookFailed))
    }
  }

  context('polls') {
    it('finds all active polls') {
      user = create_user(email: 'me@me')
      other_user = create_user(email: 'other@other')
      my_group = user.add_group(name: 'my_group')
      other_group = other_user.add_group(name: 'other_group')
      other_group.add_member(email: 'me@me')
      unrelated_group = other_user.add_group(name: 'unrelated_group')
      unrelated_group.add_poll(title: 'title',
                               question: 'question',
                               expiration: Time.now + 10)
      my_poll = my_group.add_poll(title: 'title', question: 'question',
                                  expiration: Time.now + 10)
      other_poll = other_group.add_poll(title: 'title', question: 'question',
                                        expiration: Time.now + 10)
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

    it('can add a group as creator') {
      user = create_user
      group = user.add_group(name: 'creator_group')
      expect(group.creator).to(eq(user))
    }

    it('throws error if adding duplicate groups') {
      user = create_user
      user.add_group(name: 'duplicate_name')
      expect {
        user.add_group(name: 'duplicate_name')
      }.to(raise_error(Sequel::UniqueConstraintViolation))
    }
  }

  context('add_member') {
    it('always adds itself as a member to any group') {
      user = create_user(email: 'a@a')
      group = user.add_group(name: 'name')
      expect(group.members.length).to(be(1))
      expect(group.members[0].email).to(eq(group.creator.email))
      expect(group.members[0].email).to(eq('a@a'))
    }

    it('can add an existing user as a member to a group') {
      group = create_group(email: 'a@a')
      create_user(email: 'b@b')
      member = group.add_member(email: 'b@b')
      expect(member.user).to(eq(Models::User['b@b']))
      expect(group.members).to(include(member))
    }

    it('can add a new user as a member to a group') {
      group = create_group(email: 'a@a')
      member = group.add_member(email: 'b@b')
      expect(member.user).to(eq(Models::User['b@b']))
      expect(group.members).to(include(member))
    }

    it('can add multiple members to a group') {
      group = create_group(email: 'a@a')
      member_one = group.add_member(email: 'b@b')
      member_two = group.add_member(email: 'c@c')
      expect(group.members).to(include(member_one, member_two))
    }

    it('throws error if adding member has no email') {
      group = create_group
      expect { group.add_member }.to(raise_error(ArgumentError))
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
      poll = group.add_poll(title: 'title', question: 'question',
                            expiration: Time.now)
      expect(poll.group).to(eq(group))
    }

    it('matches members from poll to its group') {
      group = create_group(email: 'a@a')
      group.add_member(email: 'b@b')
      poll = group.add_poll(title: 'title', question: 'question',
                            expiration: Time.now)
      expect(poll.members).to(match_array(group.members))
    }
  }
}
