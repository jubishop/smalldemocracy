require_relative '../models/poll'

module Helpers
  module Guard
    include Cookie

    def require_poll
      poll = Models::Poll[params.fetch(:poll_id)]
      halt(404, slim_poll(:not_found)) unless poll
      return poll
    end

    def require_email
      email = fetch_email
      halt(404, slim_email(:not_found)) unless email
      return email
    end
  end
end
