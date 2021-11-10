require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Admin < Base
  def initialize
    super

    get('/admin', ->(_, resp) {
      resp.write(@slim.render('admin/admin'))
    })

    get('/admin/poll/create', ->(_, resp) {
      resp.write(@slim.render('/poll/create'))
    })

    post('/admin/poll/create', ->(req, resp) {
      poll = Models::Poll.create(**req.params.to_h.symbolize_keys)
      resp.redirect("/admin#{poll.url}")
    })

    get(%r{^/admin/poll/view/(?<poll_id>.+)$}, ->(req, resp) {
      poll = require_poll(req, resp)

      resp.write(@slim.render('admin/view_poll', poll: poll))
    })

    get('/admin/poll/blast', ->(req, resp) {
      poll = require_poll(req, resp)

      poll.responders.each { |responder|
        Utils::Email.email(poll, responder)
      }

      resp.write(slim.render('admin/blast_emails_sent', poll: poll))
    })
  end
end
