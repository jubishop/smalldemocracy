require_relative 'poll'
require_relative 'response'

class Choice < Sequel::Model
  many_to_one :poll
  one_to_many :responses
end
