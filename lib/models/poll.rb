require 'securerandom'

class Poll < Sequel::Model
  unrestrict_primary_key

  def initialize(**args)
    args[:id] = SecureRandom.alphanumeric(16)
    super(args)
  end
end
