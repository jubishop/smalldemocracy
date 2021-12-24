require 'sequel'

module Models
  class Response < Sequel::Model
    many_to_one :choice
    many_to_one :member
    one_through_one :poll, join_table: :choices,
                           left_key: :id,
                           left_primary_key: :choice_id

    def before_validation
      cancel_action('Response created with no choice') unless choice
      cancel_action('Response created with no poll') unless poll
      cancel_action('Response created for expired poll') if poll.finished?
      super
    end

    def to_s
      choice.to_s
    end
  end
end
