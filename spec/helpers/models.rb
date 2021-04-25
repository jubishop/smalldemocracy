require_relative '../../lib/models/poll'

require_relative 'env'

module RSpec
  module Models
    def create_poll(expiration: Time.now.to_i + 62, responders: 'a@a')
      return ::Models::Poll.create_poll(title: 'title',
                                        question: 'question',
                                        expiration: expiration,
                                        choices: 'one, two, three',
                                        responders: responders)
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