require_relative '../setup'
require_relative '../lib/poll'

RSpec.describe(Poll, type: :feature) {
  # rubocop:disable Style/StringHashKeys
  Capybara.register_driver(:rack_test) {
    Capybara::RackTest::Driver.new(Rack::URLMap.new({ '/poll' => Poll }))
  }
  # rubocop:enable Style/StringHashKeys

  context('/create') {
    it('makes a poll') {
      email = fake_email_cookie
      visit '/poll/create'

      fill_in 'title', with: 'this is my title'
      fill_in 'question', with: 'what is life'
      fill_in 'responders', with: email
      fill_in 'choices', with: 'one, two, three'
      fill_in 'expiration', with: '1243121441124'
      click_button 'Submit'

      expect(page).to(have_selector('.choice', count: 3))
      expect(page).to(have_selector('.choice', count: 1, text: 'one'))
      expect(page).to(have_selector('.choice', count: 1, text: 'two'))
      expect(page).to(have_selector('.choice', count: 1, text: 'three'))
    }
  }
}
