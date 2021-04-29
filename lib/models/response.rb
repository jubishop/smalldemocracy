require 'sequel'

module Models
  class Response < Sequel::Model
    many_to_one :choice
    many_to_one :responder
    one_through_one :poll, join_table: :responders,
                           left_key: :id,
                           left_primary_key: :responder_id

    def before_validation
      cancel_action unless poll && poll.expiration >= Time.now.to_i
      super
    end

    def score
      return chosen ? poll.choices.length - rank - 1 : 0
    end

    def point
      return chosen ? 1 : 0
    end
  end
end
