module Models
  module Helpers
    class PollResults
      def initialize(responses)
        @results = {}
        responses.each { |response|
          self[response.choice].value += yield(response)
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
        return @results.values.sort!.reverse!
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
        return to_i <=> other.to_i
      end

      alias to_i value
      alias score value
      alias count value

      def text
        return choice.text
      end
      alias to_s text
    end
  end
end
