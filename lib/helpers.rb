require_relative 'utils/crypt'

module Helpers
  private

  #####################################
  # REQUIRE GUARDS
  #####################################
  def require_poll
    poll = Poll[params.fetch(:poll_id)]
    halt(404, slim_poll(:not_found)) unless poll
    return poll
  end

  def require_email
    email = fetch_email
    halt(404, slim_email(:not_found)) unless email
    return email
  end

  #####################################
  # COOKIES
  #####################################
  def fetch_email
    email = fetch_cookie(:email)
    return URI::MailTo::EMAIL_REGEXP.match?(email) ? email : false
  end

  def store_cookie(key, value)
    cookies[key] = Crypt.en(value)
  end

  def fetch_cookie(key)
    return unless cookies.key?(key)

    return Crypt.de(cookies.fetch(key))
  end
end
