require_relative '../models/poll'

module Helpers
  module Guard
    include Cookie

    def require_poll(req)
      unless req.params.key?(:hash_id)
        throw(:response, [400, 'No poll hash_id provided'])
      end

      begin
        poll = Models::Poll.with_hashid(req.params.fetch(:hash_id))
      rescue Sequel::DatabaseError => error
        puts error
      end
      throw(:response, [404, @slim.render('poll/not_found')]) unless poll

      return poll
    end

    def require_finished_poll(req)
      poll = require_poll(req)
      unless poll.finished?
        throw(:response, [403, @slim.render('poll/not_finished')])
      end
      return poll
    end

    def require_choice(req)
      choice = Models::Choice[req.params.fetch(:choice_id)]
      unless choice
        throw(:response, [404, @slim.render('poll/choice_not_found')])
      end
      return choice
    end

    def require_email(req)
      email = fetch_email(req)
      throw(:response, [404, @slim.render('email/not_found')]) unless email
      return email
    end
  end
end
