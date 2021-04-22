require 'sequel'

module Models
  class Response < Sequel::Model
    many_to_one :choice
    many_to_one :responder
  end
end
