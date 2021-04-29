require 'securerandom'
require 'sequel'
require 'set'

require_relative 'choice'
require_relative 'responder'
require_relative 'response'

module Models
  class Poll < Sequel::Model
    unrestrict_primary_key
    one_to_many :choices
    one_to_many :responders
    many_to_many :responses, join_table: :responders,
                             right_key: :id,
                             right_primary_key: :responder_id

    def self.create_poll(title:,
                         question:,
                         expiration:,
                         choices:,
                         responders:,
                         type: nil)
      options = { title: title, question: question, expiration: expiration }
      options[:type] = type if type

      raise ArgumentError, 'Choices cannot be nil' unless choices

      choices = choices.strip.split(/\s*,\s*/) if choices.is_a?(String)
      raise ArgumentError, 'There must be some choices' if choices.empty?

      raise ArgumentError, 'Responders cannot be nil' unless responders

      responders = responders.strip.split(/\s*,\s*/) if responders.is_a?(String)
      raise ArgumentError, 'There must be some responders' if responders.empty?

      poll = create(**options)
      choices.each { |choice|
        poll.add_choice(text: choice)
      }
      responders.each { |responder|
        poll.add_responder(email: responder)
      }

      return poll
    end

    def before_create
      self.id = SecureRandom.urlsafe_base64(16)
      super
    end

    def type
      return super.to_sym
    end

    def responder(**options)
      return responders_dataset.where(**options).first
    end

    def finished?
      return Time.at(expiration) < Time.now
    end

    def scores
      return unless finished?

      @scores ||= tally_results { |response|
        choices.length - response.rank - 1
      }
      return @scores
    end

    def counts
      return unless finished? && type == :borda_split

      @counts ||= tally_results { |response| response.chosen ? 1 : 0 }
      return @counts
    end

    def url(responder_salt = nil)
      return "/poll/view/#{id}" unless responder_salt

      return "/poll/view/#{id}?responder=#{responder_salt}"
    end

    private

    def tally_results(&block)
      return PollResults.new(responses, &block).to_a
    end
  end

  class PollResults
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
end
