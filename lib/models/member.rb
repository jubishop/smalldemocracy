require 'sequel'

module Models
  class Member < Sequel::Model
    many_to_one :group
    many_to_one :user, key: :email
    undef delete

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

    def to_s
      return email
    end
  end
end
