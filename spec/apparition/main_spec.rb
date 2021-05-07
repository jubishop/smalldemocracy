RSpec.describe(Main, type: :feature) {
  context('index') {
    it('displays logged out index') {
      visit('/')
      RSpec::Goldens.verify(page, 'index_logged_out', full: true)
    }

    it('displays logged in index') {
      set_cookie(:email_address, 'test@example.com')
      visit('/')
      RSpec::Goldens.verify(page, 'index_logged_in', full: true)
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('does_not_exist')
      RSpec::Goldens.verify(page, 'page_not_found', full: true)
    }
  }
}
