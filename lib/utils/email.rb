require 'sendgrid-ruby'

module Email
  def self.send_email(poll, responder)
    from = SendGrid::Email.new(name: 'JubiVote', email: 'support@jubivote.com')
    to = SendGrid::Email.new(email: responder.email)
    subject = "JubiVote poll: #{poll.title}"

    url = "https://www.jubivote.com/poll/#{poll.id}?responder=#{responder.salt}"
    body = %(<a href="#{url}">Here's a link to your survey!</a>)
    content = SendGrid::Content.new(type: 'text/html', value: body)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV.fetch('SENDGRID_API_KEY'))
    return sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
