require 'sendgrid-ruby'

module Utils
  module Email
    HOSTNAME = 'jubivote.com'.freeze
    public_constant :HOSTNAME

    def self.email(poll, responder)
      if poll.expiration < Time.now.to_i
        raise ArgumentError, "Cannot send email to #{responder.email} " \
          "because poll: #{poll.title} has expired"
      end

      from = SendGrid::Email.new(name: 'JubiVote', email: "support@#{HOSTNAME}")
      to = SendGrid::Email.new(email: responder.email)
      subject = "Poll: #{poll.title}"

      url = "https://www.#{HOSTNAME}#{responder.url}"
      slim = Tony::Slim.new(views: 'lib/utils')
      body = slim.render(:email, poll: poll, url: url)

      content = SendGrid::Content.new(type: 'text/html', value: body)
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV.fetch('SENDGRID_API_KEY'))
      return if ENV.fetch('APP_ENV') == 'test'

      return Process.detach(Process.fork {
        sg.client.mail._('send').post(request_body: mail.to_json)
      })
    end
  end
end
