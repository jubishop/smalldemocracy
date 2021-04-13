require 'securerandom'

require_relative 'models/poll'

module Admin
  def self.create_poll(title)
    Poll.new(id: SecureRandom.alphanumeric(16), title: title).save
  end
end
