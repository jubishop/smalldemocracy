RSpec.shared_examples('entity flows') { |path|
  context('logged out') {
    it('asks for email for create') {
      visit("/#{path}/create")
      expect(page).to(have_link('Sign in with Google', href: "/#{path}/create"))
      goldens.verify('create_get_email')
    }

    it('asks for email for view') {
      visit(entity.url)
      expect(page).to(have_link('Sign in with Google', href: entity.url))
      goldens.verify('view_get_email')
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit("/#{path}/invalid_hash_id")
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('not_found')
    }
  }
}
