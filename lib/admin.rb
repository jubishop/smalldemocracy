require 'core'

require_relative 'base'
require_relative 'helpers/admin/slim'
require_relative 'models/poll'
require_relative 'utils/email'

class Admin < Base
  include AdminHelpers::Slim

  get('') {
    slim_admin :admin
  }

  get('/create_poll') {
    slim_admin :create_poll
  }

  post('/new_poll') {
    poll = Poll.create_poll(**params.to_h.symbolize_keys)
    redirect "/admin/poll/#{poll.id}"
  }

  get('/poll/:poll_id') {
    poll = require_poll

    slim_admin(:poll, locals: { poll: poll })
  }

  get('/mass_email') {
    poll = require_poll

    poll.responders.each { |responder|
      logger.info("Now emailing: #{responder.email}")
      Utils::Email.send_email(poll, responder)
    }

    slim_admin(:mass_emails_sent, locals: { poll: poll })
  }
end
