require_relative 'base'
require_relative 'models/user'

class API < Base
  include Helpers::Guard

  def initialize
    super

    get('/api', ->(req, resp) {
      email = fetch_email(req)

      if email
        user = Models::User.find_or_create(email: email)
        return 200, @slim.render(:api, user: user)
      end

      resp.redirect('/')
    })

    post('/api/key/new', ->(req, _) {
      email = require_session(req)
      user = Models::User.find_or_create(email: email)
      user.update(api_key: Models::User.create_api_key)
      return 201, user.api_key
    })

    post('/api/poll/new', ->(req, _) {
      user = require_key(req)

      req.params[:email] = user.email

      choices = req.list_param(:choices, [])
      req.params.delete(:choices)

      req.params[:expiration] = require_expiration(req)

      begin
        poll = Models::Poll.create(**req.params.symbolize_keys)
        choices.each { |choice| poll.add_choice(text: choice) }
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, poll.url
      end
    })
  end

  private

  def require_key(req)
    key = req.param(:key)
    user = Models::User.find(api_key: key)
    throw(:response, [401, %(Invalid key given: "#{key}")]) unless user
    return user
  end
end
