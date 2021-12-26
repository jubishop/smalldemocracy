# Table: polls
# Columns:
#  id         | bigint                      | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  email      | text                        | NOT NULL
#  group_id   | bigint                      | NOT NULL
#  created_at | timestamp without time zone | NOT NULL
#  updated_at | timestamp without time zone | NOT NULL
#  title      | text                        | NOT NULL
#  question   | text                        | NOT NULL
#  expiration | timestamp without time zone | NOT NULL
#  type       | poll_type                   | NOT NULL DEFAULT 'borda_single'::poll_type
# Indexes:
#  polls_pkey | PRIMARY KEY btree (id)
# Check constraints:
#  question_not_empty | (char_length(question) >= 1)
#  title_not_empty    | (char_length(title) >= 1)
# Foreign key constraints:
#  polls_email_fkey    | (email) REFERENCES users(email)
#  polls_group_id_fkey | (group_id) REFERENCES groups(id) ON DELETE CASCADE
# Referenced By:
#  choices | choices_poll_id_fkey | (poll_id) REFERENCES polls(id) ON DELETE CASCADE

require 'rstruct'
require 'sequel'

require_relative 'helpers/poll_results'
require_relative 'group'
require_relative 'user'

BreakdownResult = KVStruct.new(:member, :score)

module Models
  class Poll < Sequel::Model
    many_to_one :creator, class: 'Models::User', key: :email
    many_to_one :group
    one_to_many :choices, remover: ->(choice) { choice.destroy }, clearer: nil
    many_to_many :responses, join_table: :choices,
                             right_key: :id,
                             right_primary_key: :choice_id,
                             adder: nil,
                             remover: nil,
                             clearer: nil
    plugin :timestamps, update_on_create: true
    plugin :hash_id, salt: ENV.fetch('POLL_ID_SALT').freeze

    def before_validation
      cancel_action('Poll has no group') unless group_id
      cancel_action('Poll has no creator') unless email
      cancel_action('Poll has empty creator') if email.empty?
      cancel_action("Poll has invalid creator email: '#{email}'") unless creator
      unless member(email: creator.email)
        cancel_action("Creator: '#{email}', is not a member of '#{group.name}'")
      end
      if !expiration.nil? && expiration.is_a?(Time) && expiration.to_i.zero?
        cancel_action('Poll has expiration at unix epoch')
      end
      super
    end

    def members
      return Member.where(group_id: group_id).all
    end

    def member(email:)
      return Member.find(group_id: group_id, email: email)
    end

    def creating_member
      return member(email: creator.email)
    end

    def choice(text:)
      return Choice.find(poll_id: id, text: text)
    end

    def finished?
      return Time.at(expiration) < Time.now
    end

    def scores
      assert_type(:borda_single, :borda_split)

      return Helpers::PollResults.new(responses, &:score).to_a
    end

    def counts
      assert_type(:borda_split, :choose_one)

      point_results = Helpers::PollResults.new(responses)
      case type
      when :choose_one
        return point_results.to_a
      when :borda_split
        scores_results = Helpers::PollResults.new(responses, &:score)
        return point_results.values.sort_by! { |result|
          [-result.count, -scores_results[result.choice].score]
        }
      end
    end

    def breakdown
      assert_type(:choose_one, :borda_single, :borda_split)

      results = Hash.new { |hash, key| hash[key] = [] }
      unresponded = []
      members.each { |member|
        if member.responses.empty?
          unresponded.push(member)
        else
          member.responses.each { |response|
            results[response.choice].push(BreakdownResult.new(
                                              member: member,
                                              score: response.score))
          }
        end
      }
      return results, unresponded
    end

    def type
      return super.to_sym
    end

    def url
      return "/poll/view/#{hashid}"
    end

    def to_s
      return title
    end

    private

    def assert_type(*types)
      return if types.include?(type)

      raise TypeError, "#{title} has type: #{type} but must be one of " \
                       "#{types.sentence('or')} for this method"
    end
  end
end
