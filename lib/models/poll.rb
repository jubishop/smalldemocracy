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

    Result = Struct.new(:text, :score, keyword_init: true)
    private_constant :Result

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

    def results
      return if Time.at(expiration) > Time.now

      return @@results[id] ||= compute_results
    end

    def score(response)
      return choices.length - response.rank - 1
    end

    def url(responder_salt = nil)
      return "/poll/view/#{id}" unless responder_salt

      return "/poll/view/#{id}?responder=#{responder_salt}"
    end

    private

    @@results = {}

    def compute_results
      choices_hash = choices.to_h { |choice|
        [choice.id, Result.new(text: choice.text, score: 0)]
      }

      responses.each { |response|
        choices_hash[response.choice_id].score += score(response)
      }

      return choices_hash.values.sort_by(&:score).reverse!
    end
  end
end
