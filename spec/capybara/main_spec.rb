RSpec.describe(Main, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/main') }

  # TODO: Check github and home links on top header.

  context('index') {
    def expect_header_links
      expect(page).to(have_selector('a.home[href="/"]'))
      github_url = 'https://github.com/jubishop/smalldemocracy'
      expect(page).to(have_selector("a.github[href='#{github_url}']"))
    end

    it('displays logged out index') {
      go('/')
      expect_header_links
      expect(page).to(have_link('Sign in with Google', href: '/'))
      goldens.verify('logged_out')
    }

    it('displays logged in index') {
      set_cookie(:email, 'main@loggedin')
      go('/')
      expect_header_links
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
