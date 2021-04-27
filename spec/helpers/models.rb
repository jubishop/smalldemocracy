require_relative '../../lib/models/poll'

require_relative 'env'

module RSpec
  module Models
    def create_poll(title: 'title',
                    question: 'question',
                    expiration: Time.now.to_i + 62,
                    choices: 'one, two, three',
                    responders: 'a@a',
                    type: nil)
      return ::Models::Poll.create_poll(title: title,
                                        question: question,
                                        expiration: expiration,
                                        choices: choices,
                                        responders: responders,
                                        type: type)
    end
  end
end

module Models
  class Poll
    include RSpec::Env

    def mock_response
      test_only!
      responder = responder(email: 'a@a')
      responses = choices.map(&:id)
      responses.each_with_index { |choice_id, rank|
        responder.add_response(choice_id: choice_id, rank: rank)
      }
      return responder, responses
    end
  end
end
