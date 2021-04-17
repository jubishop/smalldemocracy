require 'securerandom'

require_relative 'poll'
require_relative 'response'

class Responder < Sequel::Model
  many_to_one :poll
  one_to_many :responses

  def before_create
    super
    self.salt = SecureRandom.urlsafe_base64(8)
  end
end
