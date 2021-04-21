require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Main < Base
  get('/') {
    puts request.get_header('HTTP_X_FORWARDED_PROTO')
    puts request.get_header('HTTP_FLY_FORWARDED_PROTO')
    puts request.get_header('HTTP_FLY_FORWARDED_SSL')
    puts request.get_header('HTTP_X_FORWARDED_SSL')
    puts request.get_header('HTTP_FLY_FORWARDED_PORT')
    slim :index, locals: { email: fetch_email }
  }

  get('/logout') {
    cookies.delete(:email)
    redirect params.fetch(:r, '/')
  }
end
