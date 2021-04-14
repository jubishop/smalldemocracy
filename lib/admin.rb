require_relative 'models/poll'

module Admin
  def self.create_poll(title:, choices:, responders:)
    poll = Poll.new(title: title).save
    choices.each { |choice|
      poll.add_choice(text: choice)
    }
    responders.each { |responder|
      poll.add_responder(email: responder)
    }
    return poll.id
  end
end
