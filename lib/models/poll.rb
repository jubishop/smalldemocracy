require 'securerandom'
require 'sequel'
require 'set'

require_relative 'helpers/poll_results'

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
      return responders { |ds| ds.where(**options) }.first
    end

    def finished?
      return Time.at(expiration) < Time.now
    end

    def scores
      return unless finished?

      @scores ||= poll_results(&:score)
      return @scores
    end

    def counts
      return unless finished? && type == :borda_split

      @counts ||= poll_results(&:point)
      return @counts
    end

    def url(responder_salt = nil)
      return "/poll/view/#{id}" unless responder_salt

      return "/poll/view/#{id}?responder=#{responder_salt}"
    end

    private

    def poll_results(&block)
      return Helpers::PollResults.new(responses, &block).to_a
    end
  end
end
