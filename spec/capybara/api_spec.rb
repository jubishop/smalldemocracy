RSpec.describe(API, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/api') }
  let(:email) { 'user@api.com' }

  it('shows the API page') {
    allow(Models::User).to(receive(:create_api_key).and_return('Test API Key'))
    go('/api')
    goldens.verify('api_page')
  }
}
