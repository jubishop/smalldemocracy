require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static'

module JubiVote
  class App < Sinatra::Base
    helpers Sinatra::ContentFor
    register Sinatra::Static

    set(public_folder: 'public')
    set(views: 'views')

    get('/') {
      erb :index
    }

    get('/admin') {
      erb :admin
    }

    get('/admin/create_poll') {
      erb :create_poll
    }

    post('/admin/create_poll') {
      require 'sendgrid-ruby'
      include SendGrid

      from = SendGrid::Email.new(email: 'jubivote@jubishop.com')
      to = SendGrid::Email.new(email: 'jubi@hey.com')
      subject = 'Sending with Twilio SendGrid is Fun'
      content = SendGrid::Content.new(type: 'text/plain', value: 'and easy to do anywhere, even with Ruby')
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV.fetch('SENDGRID_API_KEY'))
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    }
  end
end
