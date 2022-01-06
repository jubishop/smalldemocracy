module Helpers
  module Email
    def invalid_email(email:, name:)
      return "#{name} has no email" unless email

      return "#{name} has empty email" if email.to_s.empty?

      return if URI::MailTo::EMAIL_REGEXP.match?(email.to_s)

      return "#{name} has invalid email: '#{email}'"
    end
  end
end
