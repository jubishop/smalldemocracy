require_relative '../models/poll'

module Helpers
  module Guard
    include Cookie

    def require_poll(req, resp)
      unless req.params.key?(:poll_id)
        resp.status = 400
        resp.write('No poll_id provided')
        throw(:response)
      end

      poll = Models::Poll[req.params.fetch(:poll_id)]
      unless poll
        resp.status = 404
        resp.write(@slim.render('poll/not_found'))
        throw(:response)
      end

      return poll
    end

    def require_email(req, resp)
      email = fetch_email(req)
      unless email
        resp.status = 404
        resp.write(@slim.render('email/not_found'))
        throw(:response)
      end
      return email
    end
  end
end
