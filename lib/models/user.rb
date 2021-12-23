require 'sequel'

require_relative 'group'

module Models
  class User < Sequel::Model
    unrestrict_primary_key
    one_to_many :groups
    undef delete

    def before_validation
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("Email: #{email}, is invalid")
      end
      super
    end

    def before_destroy
      cancel_action("Users (#{email}) cannot be removed")
    end

    def polls(cutoff = Time.now)
      group_ids = Models::Member.where(email: email).select(:group_id)
      return Models::Poll.where(
          [
            [:group_id, group_ids],
            [:expiration, cutoff..]
          ]).all
    end

    def add_group(name:)
      group = super(name: name)
      group.add_member(email: email)
      return group
    end

    def to_s
      return email
    end
  end
end
