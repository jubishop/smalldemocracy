require 'securerandom'

require_relative 'poll'

class Responder < Sequel::Model
  many_to_one :poll

  def before_create
    super
    self.salt = SecureRandom.urlsafe_base64(8)
  end
end
