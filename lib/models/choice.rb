require 'sequel'

module Models
  class Choice < Sequel::Model
    many_to_one :poll
    one_to_many :responses
  end
end
