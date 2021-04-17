require 'securerandom'

require_relative 'choice'
require_relative 'responder'

class Poll < Sequel::Model
  unrestrict_primary_key
  one_to_many :choices
  one_to_many :responders

  def self.create_poll(title:, choices:, responders:)
    poll = create(title: title)
    choices.each { |choice|
      poll.add_choice(text: choice)
    }
    responders.each { |responder|
      poll.add_responder(email: responder)
    }
    return poll
  end

  def before_create
    super
    self.id = SecureRandom.urlsafe_base64(16)
  end

  def responder(**options)
    return responders_dataset.where(**options).first
  end
end
