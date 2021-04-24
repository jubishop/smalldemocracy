RSpec.describe('/', type: :rack_test) {
  context('/') {
    it('responds to / with OK status') {
      get '/'
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_no_link(href: '/logout'))
    }

    it('does not delete the email cookie') {
      set_cookie(:email, 'nomnomnom')
      get '/'
      expect(get_cookie(:email)).to(eq('nomnomnom'))
    }

    it('welcomes user when they have email cookie') {
      set_cookie(:email, 'test@example.com')
      get '/'
      expect(last_response.body).to(have_content('test@example.com'))
      expect(last_response.body).to(have_link(href: '/logout'))
    }

    it('provides create poll link with email cookie') {
      set_cookie(:email, 'test@example.com')
      get '/'
      expect(last_response.body).to(have_link(href: '/poll/create'))
    }
  }

  context('/logout') {
    it('deletes the email cookie') {
      set_cookie(:email, 'nomnomnom')
      get '/logout'
      expect(get_cookie(:email)).to(be_nil)
    }
  }
}
