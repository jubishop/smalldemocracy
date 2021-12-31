# Table: users
# Columns:
#  email | text | PRIMARY KEY
# Indexes:
#  users_pkey | PRIMARY KEY btree (email)
# Referenced By:
#  groups  | groups_email_fkey  | (email) REFERENCES users(email)
#  members | members_email_fkey | (email) REFERENCES users(email)
#  polls   | polls_email_fkey   | (email) REFERENCES users(email)

require 'sequel'

require_relative '../helpers/email'
require_relative 'group'
require_relative 'member'
require_relative 'poll'

module Models
  class User < Sequel::Model
    include ::Helpers::Email

    unrestrict_primary_key
    one_to_many :members, key: :email, adder: nil, remover: nil, clearer: nil
    one_to_many :created_groups,
                class: 'Models::Group',
                key: :email,
                remover: ->(group) { group.destroy },
                clearer: nil
    alias add_group add_created_group
    alias remove_group remove_created_group
    one_to_many :created_polls,
                class: 'Models::Poll',
                key: :email,
                remover: ->(poll) { poll.destroy },
                clearer: nil
    alias add_poll add_created_poll
    alias remove_poll remove_created_poll

    def before_validation
      if (message = invalid_email(email: email, name: 'User'))
        cancel_action(message)
      end
      super
    end

    undef_method :delete
    def before_destroy
      cancel_action('Users cannot be destroyed')
    end

    def groups
      return Models::Group.where(id: members_dataset.select(:group_id)).all
    end

    def polls(start_expiration: nil, end_expiration: nil)
      return Models::Poll.where(
          [
            [:group_id, members_dataset.select(:group_id)],
            [:expiration, start_expiration..end_expiration]
          ]).all
    end

    def to_s
      return email
    end
  end
end
