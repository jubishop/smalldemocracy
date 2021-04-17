require 'securerandom'

require_relative 'choice'
require_relative 'responder'

class Poll < Sequel::Model
  unrestrict_primary_key

  one_to_many :choices
  eager :choices

  one_to_many :responders
  eager :responders

  def before_create
    super
    self.id = SecureRandom.urlsafe_base64(16)
  end

  def responder(**options)
    return responders_dataset.where(**options).first
  end
end
