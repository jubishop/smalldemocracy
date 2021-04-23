RSpec.describe('/poll') {
  include_context(:rack_test)

  context('/create') {
    it('rejects any access without a cookie') {
      get '/poll/create'
      expect(last_response.ok?).to(be(false))
      expect(last_response.body).to(have_content('Email Not Found'))
    }

    it('shows poll creation form if you have an email cookie') {
      set_cookie(:email, 'test@example.com')
      get '/poll/create'
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(
          have_selector('form[action="/poll/create"][method=post]'))
      expect(last_response.body).to(have_selector('input[type=submit]'))
    }
  }
}
