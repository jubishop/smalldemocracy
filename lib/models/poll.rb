require 'securerandom'

require_relative 'choice'

class Poll < Sequel::Model
  unrestrict_primary_key
  one_to_many :choices
  eager :choices

  def initialize(**args)
    args[:id] = SecureRandom.alphanumeric(16)
    super(args)
  end
end
