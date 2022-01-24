RSpec.shared_examples('entity flows') {
  context('logged out') {
    it('asks for email') {
      clear_cookies
      go(entity.url)
      expect(page).to(have_link('Sign in with Google', href: entity.url))
      goldens.verify('get_email')
    }
  }

  context('not found') {
    it('displays a not found page') {
      go(entity.url)
      goldens.verify('not_found')
    }
  }
}
