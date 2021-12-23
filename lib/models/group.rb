require 'sequel'

require_relative 'member'
require_relative 'poll'

module Models
  class Group < Sequel::Model
    many_to_one :creator, class: 'Models::User', key: :email
    one_to_many :members
    one_to_many :polls

    def _add_member(member)
      User.find_or_create(email: member.email)
      super(member)
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
