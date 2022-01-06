# Table: members
# Columns:
#  id       | bigint | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  email    | text   | NOT NULL
#  group_id | bigint | NOT NULL
# Indexes:
#  members_pkey  | PRIMARY KEY btree (id)
#  member_unique | UNIQUE btree (email, group_id)
# Foreign key constraints:
#  members_email_fkey    | (email) REFERENCES users(email)
#  members_group_id_fkey | (group_id) REFERENCES groups(id) ON DELETE CASCADE
# Referenced By:
#  responses | responses_member_id_fkey | (member_id) REFERENCES members(id) ON DELETE CASCADE

require 'sequel'

require_relative '../helpers/email'
require_relative 'group'
require_relative 'response'
require_relative 'user'

module Models
  class Member < Sequel::Model
    include ::Helpers::Email

    many_to_one :group
    many_to_one :user, key: :email
    one_to_many :responses,
                remover: ->(response) { response.destroy },
                clearer: nil

    def before_validation
      if (message = invalid_email(email: email, name: 'Member'))
        cancel_action(message)
      end
      super
    end

    def before_create
      super
      User.find_or_create(email: email)
    end

    def before_update
      cancel_action('Members are immutable')
      super
    end

    def before_destroy
      if self == group.creating_member
        cancel_action("Creators (#{email}) cannot be removed from their groups")
      end
      super
    end

    def responded?(poll_id:)
      return poll_dataset(poll_id: poll_id).count.positive?
    end

    def add_poll(**attributes)
      return Models::Poll.create(group_id: group_id, email: email, **attributes)
    end

    def responses(poll_id: nil)
      return poll_id ? poll_dataset(poll_id: poll_id).all : super
    end

    def polls(start_expiration: nil, end_expiration: nil)
      return Models::Poll.where(
          [
            [:group_id, group_id],
            [:expiration, start_expiration..end_expiration]
          ]).all
    end

    def to_s
      return email
    end

    private

    def poll_dataset(poll_id:)
      choices = Models::Choice.where(poll_id: poll_id).select(:id)
      return responses_dataset.where(choice_id: choices)
    end
  end
end
