require_relative 'models/poll'

module Admin
  def self.create_poll(title:, choices:)
    poll = Poll.new(title: title).save
    choices.each { |choice|
      poll.add_choice(text: choice)
    }
    return poll.id
  end
end
