# Table: groups
# Columns:
#  id    | bigint | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  email | text   | NOT NULL
#  name  | text   | NOT NULL
# Indexes:
#  groups_pkey  | PRIMARY KEY btree (id)
#  group_unique | UNIQUE btree (name, email)
# Check constraints:
#  name_not_empty | (char_length(name) >= 1)
# Foreign key constraints:
#  groups_email_fkey | (email) REFERENCES users(email)
# Referenced By:
#  members | members_group_id_fkey | (group_id) REFERENCES groups(id) ON DELETE CASCADE
#  polls   | polls_group_id_fkey   | (group_id) REFERENCES groups(id) ON DELETE CASCADE

require 'sequel'

require_relative 'member'
require_relative 'poll'
require_relative 'user'

module Models
  class Group < Sequel::Model
    many_to_one :creator, class: 'Models::User', key: :email
    one_to_many :members, remover: ->(member) { member.destroy }, clearer: nil
    one_to_many :polls, remover: ->(poll) { poll.destroy }, clearer: nil
    plugin :hash_id, salt: ENV.fetch('GROUP_ID_SALT').freeze

    def before_create
      super
      User.find_or_create(email: email)
    end

    def after_create
      add_member(email: email)
      super
    end

    def size
      return members_dataset.count
    end

    def creating_member
      return member(email: email)
    end

    def member(email:)
      return Member.where(group_id: id, email: email).first
    end

    def url
      return "/group/view/#{hashid}"
    end
    alias edit_url url

    def to_s
      return name
    end
  end
end
