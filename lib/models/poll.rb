require 'rstruct'
require 'securerandom'
require 'sequel'
require 'set'

require_relative 'helpers/poll_results'

require_relative 'choice'
require_relative 'exceptions'
require_relative 'responder'
require_relative 'response'

BreakdownResult = KVStruct.new(:responder, :score)

module Models
  class Poll < Sequel::Model
    one_to_many :choices
    one_to_many :responders
    many_to_many :responses, join_table: :responders,
                             right_key: :id,
                             right_primary_key: :responder_id

    def self.create(title: '',
                    question: '',
                    expiration: '',
                    choices: [],
                    responders: [],
                    type: nil)
      if title.nil? || title.empty?
        raise Models::ArgumentError, 'Title cannot be empty'
      end
      if question.nil? || question.empty?
        raise Models::ArgumentError, 'Question cannot be empty'
      end

      if responders.nil? || responders.empty?
        raise Models::ArgumentError, 'There must be some responders'
      end
      if choices.nil? || choices.empty?
        raise Models::ArgumentError, 'There must be some choices'
      end

      expiration = Time.at(expiration.to_i) unless expiration.is_a?(Time)
      raise Models::ArgumentError,
            'There must be an expiration' if expiration.to_i.zero?

      responders = responders.strip.split(/\s*,\s*/) if responders.is_a?(String)
      choices = choices.strip.split(/\s*,\s*/) if choices.is_a?(String)
      options = { title: title, question: question, expiration: expiration }
      options[:type] = type if type

      poll = super(**options)
      choices.each { |choice|
        poll.add_choice(text: choice)
      }
      responders.each { |responder|
        poll.add_responder(email: responder)
      }

      return poll
    end

    def type
      super.to_sym
    end

    def responder(**options)
      responders.find { |responder|
        options.all? { |attrib, value| responder.public_send(attrib) == value }
      }
    end

    def choice(**options)
      choices.find { |choice|
        options.all? { |attrib, value| choice.public_send(attrib) == value }
      }
    end

    def shuffled_choices
      choices.shuffle!
    end

    def finished?
      Time.at(expiration) < Time.now
    end

    def scores
      assert_type(:borda_single, :borda_split)

      return Helpers::PollResults.new(responses, &:score).to_a
    end

    def counts
      assert_type(:borda_split, :choose_one)

      point_results = Helpers::PollResults.new(responses, &:point)
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

    def url(responder = nil)
      return "/poll/view/#{id}" unless responder

      raise ArgumentError unless responders.include?(responder)

      return "/poll/view/#{id}?responder=#{responder.salt}"
    end

    def to_s
      title
    end

    private

    def assert_type(*types)
      return if types.include?(type)

      raise TypeError, "#{title} has type: #{type} but must be one of " \
                       "#{types.sentence('or')} for this method"
    end
  end
end
