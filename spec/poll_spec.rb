RSpec.describe('/poll', type: :feature) {
  context('/create') {
    it('makes a poll') {
      Capybara.current_driver = Capybara.javascript_driver
      current_time = 388341770
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      email = fake_email_cookie
      visit '/poll/create'

      fill_in 'title', with: 'this is my title'
      fill_in 'question', with: 'what is life'
      fill_in 'responders', with: email
      fill_in 'choices', with: 'one, two, three'
      fill_in 'expiration', with: current_time + 61
      click_button 'Submit'

      expect(page).to(have_selector('h1', exact_text: 'this is my title'))
      expect(page).to(have_selector('h2', exact_text: 'what is life'))
      expect(page).to(have_selector('.choice', count: 3))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'one'))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'two'))
      expect(page).to(have_selector('.choice', count: 1, exact_text: 'three'))
      expect(page).to(have_selector('p', text: '1 minute from now'))
      expect(page).to(have_button(text: 'Submit Choices'))
      RSpec::Goldens.verify(page, 'poll_respond', full: true)
      click_button 'Submit Choices'

      expect(page).to(have_content('recorded responses'))
      RSpec::Goldens.verify(page, 'poll_responded', full: true)

      allow(Time).to(receive(:now).and_return(Time.at(current_time + 62)))
      refresh
      expect(page).to(have_content('finished'))
      RSpec::Goldens.verify(page, 'poll_finished', full: true)
    }
  }
}
