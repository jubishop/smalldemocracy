# Table: choices
# Columns:
#  id      | bigint | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  poll_id | bigint | NOT NULL
#  text    | text   | NOT NULL
# Check constraints:
#  text_not_empty | (char_length(text) >= 1)
# Foreign key constraints:
#  choices_poll_id_fkey | (poll_id) REFERENCES polls(id) ON DELETE CASCADE
# Referenced By:
#  responses | responses_choice_id_fkey | (choice_id) REFERENCES choices(id) ON DELETE CASCADE

require 'sequel'

require_relative 'poll'

module Models
  class Choice < Sequel::Model
    many_to_one :poll
    one_to_many :responses

    def to_s
      text
    end
  end
end
