RSpec.describe(API, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/api') }
  let(:email) { 'user@api.com' }

  it('shows the API page') {
    api_key = 'Test API Key'
    allow(Models::User).to(receive(:create_api_key).and_return(api_key))
    go('/api')
    expect(page).to(have_css('#api-key', text: api_key))
    goldens.verify('api_page')
  }
}
