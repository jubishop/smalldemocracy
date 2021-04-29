module Models
  module Helpers
    class PollResults
      def initialize(responses)
        @results = {}
        responses.each { |response|
          self[response.choice].score += yield(response)
        }
      end

      def [](choice)
        @results[choice.id] ||= PollResult.new(choice: choice)
        return @results[choice.id]
      end

      def to_a
        return @results.values.sort!.reverse!
      end
    end

    class PollResult
      include Comparable

      attr_reader :choice
      attr_accessor :score

      def initialize(choice:, score: 0)
        @choice = choice
        @score = score
      end

      def <=>(other)
        return score <=> other.score
      end

      alias to_i score

      def text
        return choice.text
      end
      alias to_s text
    end
  end
end
