require 'securerandom'

require_relative 'choice'
require_relative 'responder'

class Poll < Sequel::Model
  unrestrict_primary_key
  one_to_many :choices
  one_to_many :responders

  Result = Struct.new(:text, :score, keyword_init: true)
  private_constant :Result

  def self.create_poll(title:, expiration:, choices:, responders:)
    poll = create(title: title, expiration: expiration)
    choices.each { |choice|
      poll.add_choice(text: choice)
    }
    responders.each { |responder|
      poll.add_responder(email: responder)
    }
    return poll
  end

  def before_create
    super
    self.id = SecureRandom.urlsafe_base64(16)
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

  private

  @@results = {}

  def compute_results
    choices_hash = choices.to_h { |choice|
      [choice.id, Result.new(text: choice.text, score: 0)]
    }

    Response.where(responder: responders).each { |response|
      choices_hash[response.choice_id].score += score(response)
    }

    return choices_hash.values.sort_by(&:score).reverse!
  end
end
