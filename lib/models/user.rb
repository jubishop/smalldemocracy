require 'sequel'

require_relative 'group'

module Models
  class User < Sequel::Model
    unrestrict_primary_key
    one_to_many :members, key: :email
    one_to_many :groups, key: :email
    one_to_many :created_polls, class: 'Models::Poll', key: :email
    alias add_poll add_created_poll

    def before_validation
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("Email: #{email}, is invalid")
      end
      super
    end

    undef_method :delete
    def before_destroy
      cancel_action("Users (#{email}) cannot be removed")
    end

    def _add_group(group)
      super(group)
      group.add_member(email: email)
    end

    def polls(start_expiration: nil, end_expiration: nil)
      group_ids = Models::Member.where(email: email).select(:group_id)
      return Models::Poll.where(
          [
            [:group_id, group_ids],
            [:expiration, start_expiration..end_expiration]
          ]).all
    end

    def to_s
      return email
    end
  end
end
