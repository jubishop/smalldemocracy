require 'securerandom'

require_relative 'choice'
require_relative 'responder'

class Response < Sequel::Model
  many_to_one :choice
  many_to_one :responder
end
