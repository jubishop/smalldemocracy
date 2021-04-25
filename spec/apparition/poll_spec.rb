RSpec.describe(Poll, type: :feature) {
  it('supports full poll lifecycle') {
    # It's 1982!
    current_time = 388341770
    allow(Time).to(receive(:now).and_return(Time.at(current_time)))

    # Create a poll
    page.set_cookie(:email, 'test@example.com')
    visit('/poll/create')
    fill_in('title', with: 'this is my title')
    fill_in('question', with: 'what is life')
    fill_in('responders', with: 'test@example.com')
    fill_in('choices', with: 'one, two, three')
    fill_in('expiration', with: current_time + 61)
    find('h1').click # Deselect any form field
    RSpec::Goldens.verify(page, 'poll_create', full: true)
    click_button('Submit')

    # Submit choices
    expect(page).to(have_fontawesome)
    expect(page).to(have_button(text: 'Submit Choices'))
    RSpec::Goldens.verify(page, 'poll_view', full: true)
    click_button 'Submit Choices'

    # See recorded responses
    RSpec::Goldens.verify(page, 'poll_responded', full: true)

    # See finished poll results
    allow(Time).to(receive(:now).and_return(Time.at(current_time + 62)))
    refresh
    RSpec::Goldens.verify(page, 'poll_finished', full: true)
  }

  context('poll') {
    it('blocks create when not logged in') {
      visit('/poll/create')
      RSpec::Goldens.verify(page, 'poll_email_not_found', full: true)
    }

    it('asks for email') {
      poll = create_poll
      visit(poll.url)
      RSpec::Goldens.verify(page, 'poll_email_get', full: true)
    }

    it('sends email') {
      poll = create_poll
      visit(poll.url)
      fill_in('email', with: 'a@a')
      click_button('Submit')
      RSpec::Goldens.verify(page, 'poll_email_sent', full: true)
    }

    it('complains when invalid email given') {
      poll = create_poll
      visit(poll.url)
      fill_in('email', with: 'poop@hey')
      click_button('Submit')
      RSpec::Goldens.verify(page, 'poll_email_responder_not_found', full: true)
    }

    it('responds when poll not found') {
      visit('/poll/view/does_not_exist')
      RSpec::Goldens.verify(page, 'poll_not_found', full: true)
    }
  }
}
