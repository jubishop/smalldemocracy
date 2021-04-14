require 'securerandom'

require_relative 'poll'

class Responder < Sequel::Model
  many_to_one :poll

  def before_create
    puts "in before create/!"
    super
    self.hash = SecureRandom.alphanumeric(8)
  end
end
