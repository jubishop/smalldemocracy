require 'sequel'

module Models
  class Member < Sequel::Model
    many_to_one :group
    many_to_one :user, key: :email

    def before_validation
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("Email: #{email}, is invalid")
      end
      super
    end

    def to_s
      return email
    end
  end
end
