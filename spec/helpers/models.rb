require_relative '../../lib/models/poll'
require_relative '../../lib/models/user'

module RSpec
  module Models
    def create_user(email: "#{rand}@#{rand}")
      return ::Models::User.find_or_create(email: email)
    end

    def create_group(email: "#{rand}@#{rand}", name: rand.to_s)
      return create_user(email: email).add_group(name: name)
    end

    def create_poll(email: "#{rand}@#{rand}",
                    name: rand.to_s,
                    title: rand.to_s,
                    question: rand.to_s,
                    expiration: Time.now,
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
                      expiration: Time.now,
                      text: rand.to_s,
                      **attributes)
      return create_poll(email: email,
                         name: name,
                         title: title,
                         question: question,
                         expiration: expiration,
                         **attributes).add_choice(text: text)
    end
  end
end

module Models
  class User
    include Test::Env
    orig_add_group = instance_method(:add_group)
    define_method(:add_group) { |name: rand.to_s|
      test_only!
      orig_add_group.bind_call(self, name: name)
    }
  end

  class Group
    include Test::Env
    orig_add_poll = instance_method(:add_poll)
    define_method(:add_poll) { |email: members.sample.email,
                                title: rand.to_s,
                                question: rand.to_s,
                                expiration: Time.now,
                                **attributes|
      test_only!
      orig_add_poll.bind_call(self, email: email,
                                    title: title,
                                    question: question,
                                    expiration: expiration,
                                    **attributes)
    }

    orig_add_member = instance_method(:add_member)
    define_method(:add_member) { |email: "#{rand}@#{rand}"|
      test_only!
      orig_add_member.bind_call(self, email: email)
    }
  end

  class Poll
    include Test::Env
    orig_add_choice = instance_method(:add_choice)
    define_method(:add_choice) { |text: rand.to_s|
      test_only!
      orig_add_choice.bind_call(self, text: text)
    }

    def mock_response
      test_only!
      responder = responder(email: 'a@a')
      responses = choices.map(&:id)

      case type
      when :borda_single, :borda_split
        responses.each_with_index { |choice_id, rank|
          score = responses.length - rank
          score -= 1 if type == :borda_single

          responder.add_response(choice_id: choice_id, score: score)
        }
      when :choose_one
        responder.add_response(choice_id: choices.first.id)
      end

      return responses
    end
  end

  class Choice
    include Test::Env
    orig_add_response = instance_method(:add_response)
    define_method(:add_response) { |score: rand(100), **attributes|
      test_only!
      orig_add_response.bind_call(self, score: score, **attributes)
    }
  end
end
