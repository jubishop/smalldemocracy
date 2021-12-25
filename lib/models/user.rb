# Table: users
# Columns:
#  email | text | PRIMARY KEY
# Referenced By:
#  groups  | groups_email_fkey  | (email) REFERENCES users(email)
#  members | members_email_fkey | (email) REFERENCES users(email)
#  polls   | polls_email_fkey   | (email) REFERENCES users(email)

require 'sequel'

module Models
  class User < Sequel::Model
    unrestrict_primary_key
    one_to_many :members, key: :email, adder: nil
    one_to_many :created_groups, class: 'Models::Group', key: :email
    alias add_group add_created_group
    one_to_many :created_polls, class: 'Models::Poll', key: :email
    alias add_poll add_created_poll

    def before_validation
      cancel_action('User created with no email') unless email
      cancel_action('User created with empty email') if email.empty?
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        cancel_action("User created with invalid email: '#{email}'")
      end
      super
    end

    undef_method :delete
    def before_destroy
      cancel_action('Users cannot be destroyed')
    end

    def _add_created_group(group)
      super(group)
      group.add_member(email: email)
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
