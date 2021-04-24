require_relative '../../lib/models/poll'

module RSpec
  module Models
    def create_poll(expiration: Time.now.to_i + 62)
      return ::Models::Poll.create_poll(title: 'title',
                                        question: 'question',
                                        expiration: expiration,
                                        choices: 'one, two, three',
                                        responders: 'a@a')
    end
  end
end

module Models
  class Poll
    def mock_response
      responder = responder(email: 'a@a')
      responses = choices.map(&:id)
      responses.each_with_index { |choice_id, rank|
        responder.add_response(choice_id: choice_id, rank: rank)
      }
      return responder, responses
    end
  end
end
