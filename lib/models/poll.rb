require 'securerandom'

require_relative 'choice'
require_relative 'responder'

class Poll < Sequel::Model
  unrestrict_primary_key

  one_to_many :choices
  eager :choices

  one_to_many :responders

  def initialize(**args)
    args[:id] = SecureRandom.alphanumeric(16)
    super(args)
  end
end
