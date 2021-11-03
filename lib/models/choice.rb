require 'sequel'

module Models
  class Choice < Sequel::Model
    many_to_one :poll
    one_to_many :responses

    include Comparable
    def <=>(other)
      to_s <=> other.to_s
    end

    def to_s
      text
    end
  end
end
