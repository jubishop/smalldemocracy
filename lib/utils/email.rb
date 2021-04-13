require 'sendgrid-ruby'

module Email
  def send_email
    from = SendGrid::Email.new(email: 'jubivote@jubishop.com')
    to = SendGrid::Email.new(email: 'jubi@hey.com')
    subject = 'Sending with Twilio SendGrid is Fun'
    content = SendGrid::Content.new(type: 'text/plain',
                                    value: 'and easy to do anywhere')
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV.fetch('SENDGRID_API_KEY'))
    response = sg.client.mail._('send').post(request_body: mail.to_json)
    puts response.status_code
    puts response.body
    puts response.headers
  end
end
