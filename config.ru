require 'rack/ssl-enforcer'

require_relative 'lib/jubivote'

use Rack::SslEnforcer unless Socket.gethostname.end_with?('local')
use Rack::Session::Cookie, secret: ENV.fetch('JUBIGEM_COOKIE_SECRET')
use Rack::Protection

class WriteOnlyAuth < Rack::Auth::Basic
  def call(env)
    Rack::Request.new(env).get? ? @app.call(env) : super(env)
  end
end
use(WriteOnlyAuth, 'jubigems') { |_, password|
  Rack::Utils.secure_compare(ENV.fetch('JUBIGEM_PASSWORD'), password)
}

run JubiVote::App
