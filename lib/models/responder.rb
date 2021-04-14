require_relative 'poll'

class Responder < Sequel::Model
  many_to_one :poll
end
