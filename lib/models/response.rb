require 'sequel'

require_relative 'choice'
require_relative 'responder'

module Models
  class Response < Sequel::Model
    many_to_one :choice
    many_to_one :responder
  end
end
