require_relative 'poll'

class Choice < Sequel::Model
  many_to_one :poll
end
