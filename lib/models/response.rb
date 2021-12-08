require 'sequel'

module Models
  class Response < Sequel::Model
    many_to_one :choice
    many_to_one :responder
    one_through_one :poll, join_table: :responders,
                           left_key: :id,
                           left_primary_key: :responder_id

    def before_validation
      unless poll && poll.expiration >= Time.now
        cancel_action('Poll has already finished')
      end
      super
    end

    def score
      chosen && rank ? poll.choices.length - rank : 0
    end

    def point
      chosen ? 1 : 0
    end

    def to_s
      choice.to_s
    end
  end
end
