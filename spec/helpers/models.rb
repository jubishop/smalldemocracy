require 'core/test'

require_relative '../../lib/models/choice'
require_relative '../../lib/models/group'
require_relative '../../lib/models/member'
require_relative '../../lib/models/poll'
require_relative '../../lib/models/response'
require_relative '../../lib/models/user'
require_relative 'email'
require_relative 'time'

module RSpec
  module Models
    include RSpec::EMail

    def create_user(email: random_email)
      return ::Models::User.find_or_create(email: email)
    end

    def create_group(email: random_email, name: rand.to_s)
      return ::Models::Group.create(email: email, name: name)
    end

    def create_member(email: random_email,
                      name: rand.to_s)
      return create_group(email: email, name: name).creating_member
    end

    def create_poll(email: random_email,
                    name: rand.to_s,
                    group_id: create_group(email: email, name: name).id,
                    title: rand.to_s,
                    question: rand.to_s,
                    expiration: future,
                    type: :choose_one)
      return ::Models::Poll.create(
          email: email,
          group_id: group_id,
          title: title,
          question: question,
          expiration: expiration,
          type: type)
    end

    def create_choice(text: rand.to_s, **attributes)
      return create_poll(**attributes).add_choice(text: text)
    end

    def create_response(data: nil, **attributes)
      choice = create_choice(**attributes)
      return choice.add_response(data: data)
    end
  end
end

module Models
  class User
    include RSpec::Time
    include Test::Env

    def add_group(name: rand.to_s)
      test_only!
      add_created_group(name: name)
    end

    def add_poll(group_id: groups.sample&.id,
                 title: rand.to_s,
                 question: rand.to_s,
                 expiration: future,
                 type: :choose_one)
      test_only!
      add_created_poll(group_id: group_id,
                       title: title,
                       question: question,
                       expiration: expiration,
                       type: type)
    end
  end

  class Group
    include RSpec::EMail
    include RSpec::Time
    include Test::Env

    def add_poll(email: members.sample&.email,
                 title: rand.to_s,
                 question: rand.to_s,
                 expiration: future,
                 type: :choose_one)
      test_only!
      super(email: email,
            title: title,
            question: question,
            expiration: expiration,
            type: type)
    end

    def add_member(email: random_email)
      test_only!
      super(email: email)
    end
  end

  class Member
    include RSpec::Time
    include Test::Env

    def add_response(choice_id: polls.sample.choices.sample,
                     data: nil)
      test_only!
      super(choice_id: choice_id, data: data)
    end
  end

  class Poll
    include Test::Env

    def add_choice(text: rand.to_s)
      test_only!
      super(text: text)
    end
  end

  class Choice
    include Test::Env

    def add_response(member_id: poll.members.sample.id,
                     **attributes)
      test_only!
      super(member_id: member_id, **attributes)
    end
  end
end
