require_relative '../../lib/models/choice'
require_relative '../../lib/models/group'
require_relative '../../lib/models/member'
require_relative '../../lib/models/poll'
require_relative '../../lib/models/response'
require_relative '../../lib/models/user'

module RSpec
  module Models
    def create_user(email: "#{rand}@#{rand}")
      return ::Models::User.find_or_create(email: email)
    end

    def create_group(email: "#{rand}@#{rand}", name: rand.to_s)
      return create_user(email: email).add_group(name: name)
    end

    def create_member(email: "#{rand}@#{rand}",
                      name: rand.to_s)
      return create_group(email: email, name: name).creating_member
    end

    def create_poll(email: "#{rand}@#{rand}",
                    name: rand.to_s,
                    title: rand.to_s,
                    question: rand.to_s,
                    expiration: future,
                    **attributes)
      return create_group(email: email, name: name).add_poll(
          email: email,
          title: title,
          question: question,
          expiration: expiration,
          **attributes)
    end

    def create_choice(email: "#{rand}@#{rand}",
                      name: rand.to_s,
                      title: rand.to_s,
                      question: rand.to_s,
                      expiration: future,
                      text: rand.to_s,
                      **attributes)
      return create_poll(email: email,
                         name: name,
                         title: title,
                         question: question,
                         expiration: expiration,
                         **attributes).add_choice(text: text)
    end

    def create_response(email: "#{rand}@#{rand}",
                        name: rand.to_s,
                        title: rand.to_s,
                        question: rand.to_s,
                        expiration: future,
                        text: rand.to_s,
                        score: nil,
                        **attributes)
      choice = create_choice(email: email,
                             name: name,
                             title: title,
                             question: question,
                             expiration: expiration,
                             text: text,
                             **attributes)
      return choice.add_response(score: score)
    end
  end
end

module Models
  class User
    include Test::Env
    def add_group(name: rand.to_s)
      test_only!
      add_created_group(name: name)
    end

    def add_poll(group_id: groups.sample&.id,
                 title: rand.to_s,
                 question: rand.to_s,
                 expiration: ::Time.now,
                 **attributes)
      test_only!
      add_created_poll(group_id: group_id,
                       title: title,
                       question: question,
                       expiration: expiration,
                       **attributes)
    end
  end

  class Group
    include Test::Env
    def add_poll(email: members.sample&.email,
                 title: rand.to_s,
                 question: rand.to_s,
                 expiration: ::Time.now,
                 **attributes)
      test_only!
      super(email: email,
            title: title,
            question: question,
            expiration: expiration,
            **attributes)
    end

    def add_member(email: "#{rand}@#{rand}")
      test_only!
      super(email: email)
    end
  end

  class Member
    include Test::Env
    orig_add_poll = instance_method(:add_poll)
    undef_method(:add_poll)
    define_method(:add_poll) { |title: rand.to_s,
                                question: rand.to_s,
                                expiration: ::Time.now,
                                **attributes|
      test_only!
      orig_add_poll.bind_call(self, title: title,
                                    question: question,
                                    expiration: expiration,
                                    **attributes)
    }

    def add_response(choice_id: polls.sample.choices.sample,
                     score: nil)
      test_only!
      super(choice_id: choice_id, score: score)
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
