require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Admin < Base
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
      Email.send_email(poll, responder)
    }

    slim_admin(:mass_emails_sent, locals: { poll: poll })
  }

  private

  #####################################
  # SLIM TEMPLATES
  #####################################
  def slim_admin(template, **options)
    slim(template, **options.merge(views: 'views/admin', layout: :'../layout'))
  end
end
