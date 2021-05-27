require 'sequel'

module Models
  class Choice < Sequel::Model
    many_to_one :poll
    one_to_many :responses

    def to_s
      text
    end
  end
end
