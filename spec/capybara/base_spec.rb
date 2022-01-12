RSpec.describe(Base, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/base') }

  context('not_found') {
    it('displays a not found page') {
      go('/does_not_exist')
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('not_found')
    }
  }

  context(:production) {
    before(:each) {
      ENV['APP_ENV'] = 'production'
      ENV['RACK_ENV'] = 'production'
    }

    it('displays an error page') {
      go('throw_error')
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('error')
    }
  }
}
