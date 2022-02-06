RSpec.shared_examples('auth flow') {
  def auth_get(login_info)
    # rubocop:disable Style/StringHashKeys
    get(path, {}, { 'login_info' => login_info })
    # rubocop:enable Style/StringHashKeys
  end

  it('sets the email address') {
    set_cookie(:email, random_email)
    auth_get(Tony::Auth::LoginInfo.new(email: email))
    expect(get_cookie(:email)).to(eq(email))
  }

  it('redirects to / by default') {
    auth_get(Tony::Auth::LoginInfo.new(email: email))
    expect(last_response.redirect?).to(be(true))
    expect(last_response.location).to(eq('/'))
  }

  it('redirects to :r in state') {
    auth_get(Tony::Auth::LoginInfo.new(email: email, state: { r: '/onward' }))
    expect(last_response.redirect?).to(be(true))
    expect(last_response.location).to(eq('/onward'))
  }

  it('defaults to / when there is no :r in state') {
    auth_get(Tony::Auth::LoginInfo.new(email: email, state: {}))
    expect(last_response.redirect?).to(be(true))
    expect(last_response.location).to(eq('/'))
  }

  it('redirects to / when there is no login_info') {
    auth_get(nil)
    expect(last_response.redirect?).to(be(true))
    expect(last_response.location).to(eq('/'))
  }
}
