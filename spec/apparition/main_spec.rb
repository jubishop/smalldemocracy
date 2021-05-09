RSpec.describe(Main, type: :feature) {
  let(:goldens) { Tony::Goldens.new(page) }

  context('index') {
    it('displays logged out index') {
      visit('/')
      goldens.verify('index_logged_out')
    }

    it('displays logged in index') {
      set_cookie(:email_address, 'test@example.com')
      visit('/')
      goldens.verify('index_logged_in')
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('does_not_exist')
      goldens.verify('page_not_found')
    }
  }
}
