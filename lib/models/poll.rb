require 'rstruct'
require 'sequel'

require_relative 'helpers/poll_results'

BreakdownResult = KVStruct.new(:responder, :score)

module Models
  class Poll < Sequel::Model
    many_to_one :group
    one_to_many :choices
    plugin :timestamps, update_on_create: true

    def members
      return Models::Member.where(group_id: group_id).all
    end

    def type
      return super.to_sym
    end

    def shuffled_choices
      return choices.shuffle!
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
      responders.each { |responder|
        if responder.responses.empty?
          unresponded.push(responder)
        else
          responder.responses.each { |response|
            results[response.choice].push(BreakdownResult.new(
                                              responder: responder,
                                              score: response.score))
          }
        end
      }
      return results, unresponded
    end

    def url
      return "/poll/view/#{id}"
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
