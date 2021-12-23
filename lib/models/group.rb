require 'sequel'

require_relative 'member'
require_relative 'poll'

module Models
  class Group < Sequel::Model
    many_to_one :user, key: :email
    one_to_many :members
    one_to_many :polls
    alias creator user

    def add_member(email:)
      User.find_or_create(email: email)
      return super(email: email)
    end

    def creating_member
      return member(email: email)
    end

    def member(email:)
      return Member.find(group_id: id, email: email)
    end

    def url
      return "/group/view/#{id}"
    end

    def to_s
      return name
    end
  end
end
