require 'securerandom'
require 'sequel'
require 'set'

require_relative 'helpers/poll_results'

require_relative 'choice'
require_relative 'exceptions'
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

    def self.create(title:,
                    question:,
                    expiration:,
                    choices:,
                    responders:,
                    type: nil)
      raise Models::ArgumentError, 'Choices cannot be nil' unless choices

      choices = choices.strip.split(/\s*,\s*/) if choices.is_a?(String)
      raise Models::ArgumentError,
            'There must be some choices' if choices.empty?

      raise Models::ArgumentError, 'Responders cannot be nil' unless responders

      responders = responders.strip.split(/\s*,\s*/) if responders.is_a?(String)
      raise Models::ArgumentError,
            'There must be some responders' if responders.empty?

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

    def before_create
      self.id = SecureRandom.urlsafe_base64(16)
      super
    end

    def type
      return super.to_sym
    end

    def responder(**options)
      return responders.find { |responder|
        options.all? { |attrib, value| responder.public_send(attrib) == value }
      }
    end

    def choice(**options)
      return choices.find { |choice|
        options.all? { |attrib, value| choice.public_send(attrib) == value }
      }
    end

    def finished?
      return Time.at(expiration) < Time.now
    end

    def scores
      assert_type(:borda_single, :borda_split)

      @scores ||= poll_results(&:score)
      return @scores
    end

    def counts
      assert_type(:borda_split, :choose_one)

      @counts ||= poll_results(&:point)
      return @counts
    end

    def breakdown
      assert_type(:choose_one)

      results = Hash.new { |hash, key| hash[key] = [] }
      unresponded = []
      responders.each { |responder|
        if responder.responses.empty?
          unresponded.push(responder)
        else
          results[responder.response.choice].push(responder)
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

    def poll_results(&block)
      return Helpers::PollResults.new(responses, &block).to_a
    end

    def assert_type(*types)
      return if types.include?(type)

      raise TypeError, "#{title} has type: #{type} but must be one of " \
                       "#{types.sentence('or')} for this method"
    end
  end
end
