require 'securerandom'
require 'sequel'

require_relative 'response'

module Models
  class Responder < Sequel::Model
    many_to_one :poll
    one_to_many :responses

    def before_validation
      cancel_action unless URI::MailTo::EMAIL_REGEXP.match?(email)
      super
    end

    def before_create
      self.salt = SecureRandom.urlsafe_base64(8)
      super
    end

    def response
      return responses.first if responses.length == 1 && responses.first.chosen

      raise RangeError, "#{email} has #{responses.length} responses for " \
                        "#{poll.title}, but should only have one that is chosen"
    end

    def url
      return poll.url(self)
    end
  end
end
