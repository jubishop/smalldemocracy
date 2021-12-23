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
  end
end

module Models
  class Group
    include Test::Env

    def add_poll(title: 'title',
                 question: 'question',
                 expiration: Time.now)
      test_only!
      super(title: title, question: question, expiration: expiration)
    end
  end

  class Poll
    include Test::Env

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
end
