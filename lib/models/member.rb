require 'sequel'

require_relative 'response'

module Models
  class Member < Sequel::Model
    many_to_one :group
    many_to_one :user, key: :email
    one_to_many :responses

    def before_validation
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("Email: #{email}, is invalid")
      end
      super
    end

    def before_destroy
      if email == group.creator.email
        cancel_action("Creators (#{email}) cannot be removed from their groups")
      end
      super
    end

    def add_poll(**attributes)
      group.add_poll(email: email, **attributes)
    end

    def to_s
      return email
    end
  end
end
