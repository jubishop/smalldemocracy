require_relative 'models/poll'

module Admin
  def self.create_poll(title)
    Poll.new(title: title).save
  end
end
