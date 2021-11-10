require 'tony'

require_relative 'helpers/cookie'
require_relative 'helpers/guard'

class Base < Tony::App
  include Helpers::Cookie
  include Helpers::Guard

  def initialize
    super(secret: ENV.fetch('JUBIVOTE_COOKIE_SECRET'))

    not_found(->(_, resp) {
      resp.write(@slim.render(:not_found))
    })
  end
end
