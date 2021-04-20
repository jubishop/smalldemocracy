require 'core'

require_relative 'base'
require_relative 'helpers/admin/slim'
require_relative 'models/poll'
require_relative 'utils/email'

class Admin < Base
  include AdminHelpers::Slim

  get('/') {
    slim_admin :admin
  }

  get('/poll/create') {
    slim_admin :create_poll
  }

  post('/poll/create') {
    poll = Models::Poll.create_poll(**params.to_h.symbolize_keys)
    redirect "/admin/poll/view/#{poll.id}"
  }

  get('/poll/view/:poll_id') {
    poll = require_poll

    slim_admin(:view_poll, locals: { poll: poll })
  }

  get('/poll/blast') {
    poll = require_poll

    poll.responders.each { |responder|
      logger.info("Now emailing: #{responder.email}")
      Utils::Email.email(poll, responder)
    }

    slim_admin(:blast_emails_sent, locals: { poll: poll })
  }
end
