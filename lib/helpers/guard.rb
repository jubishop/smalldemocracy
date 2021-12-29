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

    def require_email(req)
      email = fetch_email(req)
      unless email
        if req.get?
          throw(:response, [200, @slim.render('email/get', req: req)])
        else
          throw(:response, [404, @slim.render('email/not_found')])
        end
      end
      return email
    end
  end
end
