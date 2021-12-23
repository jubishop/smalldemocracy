require 'sequel'

require_relative 'member'

module Models
  class Group < Sequel::Model
    many_to_one :user
    one_to_many :members
    one_to_many :polls
    undef delete
    alias creator user

    def add_member(email:)
      User.find_or_create(email: email)
      return super(email: email)
    end

    def to_s
      return name
    end
  end
end
