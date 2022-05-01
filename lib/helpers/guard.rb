require_relative '../models/poll'
require_relative 'cookie'

module Helpers
  module Guard
    include Cookie

    PRIVILEGED_USERS = %w[
      jubishop@gmail.com jubi@google.com jubi@hey.com
    ].freeze
    private_constant :PRIVILEGED_USERS

    def session_is_privileged?(req)
      return PRIVILEGED_USERS.include?(fetch_email(req))
    end

    def require_session(req)
      email = fetch_email(req)
      unless email
        if req.get?
          throw(:response, [401, @slim.render(:get_email, req: req)])
        else
          throw(:response, [401, 'No email found'])
        end
      end
      return email
    end

    def require_group(req)
      begin
        group = Models::Group.with_hashid(req.param(:hash_id))
      rescue Hashids::InputError
        # Ignore
      end
      unless group
        if req.get?
          throw(:response, [404, @slim.render('group/not_found')])
        else
          throw(:response, [404, 'No group found'])
        end
      end
      return group
    end

    def require_poll(req)
      begin
        poll = Models::Poll.with_hashid(req.param(:hash_id))
      rescue Hashids::InputError
        # Ignore
      end
      unless poll
        if req.get?
          throw(:response, [404, @slim.render('poll/not_found')])
        else
          throw(:response, [404, 'No poll found'])
        end
      end
      return poll
    end

    def require_expiration(req)
      utc_time = Time.strptime("#{req.param(:expiration)} UTC",
                               '%Y-%m-%dT%H:%M %Z')
      current_offset = req.timezone.current_period.utc_total_offset
      period_time = utc_time - current_offset
      period_offset = req.timezone.period_for(period_time).utc_total_offset
      return period_time - (period_offset - current_offset)
    rescue ArgumentError
      throw(:response, [400, "#{req.param(:expiration)} is invalid date"])
    end
  end
end
