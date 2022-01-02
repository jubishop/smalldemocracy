RSpec.describe(Main, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/main') }

  context('index') {
    it('displays logged out index') {
      visit('/')
      expect(page).to(have_link('Sign in with Google', href: '/'))
      goldens.verify('index_logged_out')
    }

    it('displays logged in index') {
      set_cookie(:email, 'my@email')
      visit('/')
      expect(page).to(have_link('Create Poll', href: '/poll/create'))
      expect(page).to(have_link('Create Group', href: '/group/create'))
      goldens.verify('index_logged_in')
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('/does_not_exist')
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('page_not_found')
    }
  }
}
