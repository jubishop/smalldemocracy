RSpec.describe('/poll', type: :feature) {
  include_context(:apparition)

  def create_poll(email:, time:)
    visit('/poll/create')
    fill_in('title', with: 'this is my title')
    fill_in('question', with: 'what is life')
    fill_in('responders', with: email)
    fill_in('choices', with: 'one, two, three')
    fill_in('expiration', with: time)
    click_button('Submit')
  end

  context('/create') {
    it('kicks off a full poll lifecycle') {
      current_time = 388341770
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      # Create a poll
      page.set_cookie(:email, 'test@example.com')
      create_poll(email: 'test@example.com', time: current_time + 61)

      # Fill in poll choices
      expect(page).to(have_fontawesome)
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

      # See recorded responses
      expect(page).to(have_content('recorded responses'))
      RSpec::Goldens.verify(page, 'poll_responded', full: true)

      # See finished poll results
      allow(Time).to(receive(:now).and_return(Time.at(current_time + 62)))
      refresh
      expect(page).to(have_content('finished'))
      RSpec::Goldens.verify(page, 'poll_finished', full: true)
    }
  }
}
