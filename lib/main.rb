require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Main < Base
  get('/') {
    puts request.get_header('rack.url_scheme')
    slim :index, locals: { email: fetch_email }
  }

  get('/logout') {
    cookies.delete(:email)
    redirect params.fetch(:r, '/')
  }
end
