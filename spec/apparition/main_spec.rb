RSpec.describe(Main, type: :feature) {
  context('index') {
    it('displays logged out index') {
      visit('/')
      RSpec::Goldens.verify(page, 'index_logged_out', full: true)
    }

    it('displays logged in index') {
      page.set_cookie(:email, 'test@example.com')
      visit('/')
      RSpec::Goldens.verify(page, 'index_logged_in', full: true)
    }
  }
}
