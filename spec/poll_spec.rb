require_relative '../setup'
require_relative '../lib/poll'

# rubocop:disable Style/StringHashKeys
Capybara.register_driver(:rack_test) {
  Capybara::RackTest::Driver.new(Rack::URLMap.new({ '/poll' => Poll }))
}
# rubocop:enable Style/StringHashKeys

RSpec.describe(Poll, type: :feature) {
  context('/create') {
    it('makes a poll') {
      email = fake_email_cookie
      visit '/poll/create'

      fill_in 'title', with: 'this is my title'
      fill_in 'question', with: 'what is life'
      fill_in 'responders', with: email
      fill_in 'choices', with: 'one, two, three'
      fill_in 'expiration', with: Time.now.to_i + 90
      click_button 'Submit'

      expect(page).to(have_selector('h1', exact_text: 'this is my title'))
      expect(page).to(have_selector('h2', exact_text: 'what is life'))
      expect(page).to(have_selector('.choice', count: 3))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'one'))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'two'))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'three'))
      expect(page).to(have_selector('p', text: '1 minute from now'))
    }
  }
}