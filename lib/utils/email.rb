require 'sendgrid-ruby'

require_relative 'async'

module Utils
  module Email
    def self.email(poll, responder)
      return if ENV.fetch('APP_ENV') == 'test'

      from = SendGrid::Email.new(name: 'JubiVote',
                                 email: 'support@jubivote.com')
      to = SendGrid::Email.new(email: responder.email)
      subject = "Poll: #{poll.title}"

      path = 'https://www.jubivote.com/poll/view'
      url = "#{path}/#{poll.id}?responder=#{responder.salt}"
      body = %(
        Please <a href="#{url}">click here</a> to answer the poll:
        <b>#{poll.title}</b>: #{poll.question}.
      )

      content = SendGrid::Content.new(type: 'text/html', value: body)
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV.fetch('SENDGRID_API_KEY'))

      Async.run {
        sg.client.mail._('send').post(request_body: mail.to_json)
      }
    end
  end
end
