require_relative '../models/poll'
require_relative 'cookie'

module Helpers
  module Guard
    include Cookie

    def require_group(req)
      begin
        group = Models::Group.with_hashid(req.params[:hash_id])
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
        poll = Models::Poll.with_hashid(req.params[:hash_id])
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

    def require_email(req)
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
  end
end
