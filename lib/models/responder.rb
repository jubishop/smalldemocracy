require 'securerandom'
require 'sequel'

require_relative 'response'

module Models
  class Responder < Sequel::Model
    many_to_one :poll
    one_to_many :responses

    def before_validation
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("Email: #{email}, is invalid")
      end
      super
    end

    def response
      return responses.first if responses.length == 1

      raise RangeError, "#{email} has #{responses.length} responses for " \
                        "#{poll}, but should only have one"
    end

    def to_s
      email
    end
  end
end
