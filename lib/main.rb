require 'core'

require_relative 'base'
require_relative 'models/poll'
require_relative 'utils/email'

class Main < Base
  get('/') {
    puts request.host
    puts request.host_authority
    puts request.authority
    puts request.forwarded_authority
    puts request.forwarded_port
    puts request.hostname
    puts request.port
    puts request.server_authority
    puts request.scheme
    slim :index, locals: { email: fetch_email }
  }

  get('/logout') {
    cookies.delete(:email)
    redirect params.fetch(:r, '/')
  }
end
