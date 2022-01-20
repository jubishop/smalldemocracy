module Models
  module Helpers
    class PollResults
      def initialize(responses)
        @results = {}
        responses.each { |response|
          self[response.choice].value += block_given? ? yield(response) : 1
        }
      end

      def [](choice)
        @results[choice.id] ||= PollResult.new(choice)
        return @results[choice.id]
      end

      def values
        return @results.values
      end

      def to_a
        return values.sort_by! { |result| -result.to_i }
      end
    end

    class PollResult
      include Comparable

      attr_reader :choice
      attr_accessor :value

      def initialize(choice, value = 0)
        @choice = choice
        @value = value
      end

      def <=>(other)
        to_i <=> other.to_i
      end

      alias to_i value

      def text
        choice.text
      end
      alias to_s text
    end
  end
end
