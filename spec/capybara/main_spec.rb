RSpec.describe(Main, type: :feature) {
  let(:goldens) { RSpec::Goldens::Page.new(page, 'spec/goldens/main') }

  context('index') {
    it('displays logged out index') {
      go('/')
      expect(page).to(have_link('Sign in with Google', href: '/'))
      goldens.verify('logged_out')
    }

    it('displays logged in index') {
      set_cookie(:email, 'main@loggedin')
      go('/')
      expect(page).to(have_link('Create Poll', href: '/poll/create'))
      expect(page).to(have_link('Create Group', href: '/group/create'))
      goldens.verify('logged_in')
    }
  }

  context('not found') {
    it('displays a not found page') {
      go('/does_not_exist')
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('not_found')
    }
  }
}
