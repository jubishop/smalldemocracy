RSpec.describe('/poll', type: :feature, js: true) {
  include_context(:capybara)

  def verify_poll_page(filename)
    expect(page).to(have_fontawesome)
    expect(page).to(have_button(text: 'Submit Choices'))
    RSpec::Goldens.verify(page, filename, full: true)
  end

  it('supports full poll lifecycle') {
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
    click_button('Submit')

    # Fill in poll choices
    verify_poll_page('poll_respond')
    click_button 'Submit Choices'

    # See recorded responses
    RSpec::Goldens.verify(page, 'poll_responded', full: true)

    # See finished poll results
    allow(Time).to(receive(:now).and_return(Time.at(current_time + 62)))
    refresh
    RSpec::Goldens.verify(page, 'poll_finished', full: true)
  }

  context('poll') {
    def create_poll
      return Models::Poll.create_poll(title: 'title',
                                      question: 'question',
                                      expiration: Time.now.to_i + 62,
                                      choices: 'one, two, three',
                                      responders: 'a@a')
    end

    it('asks for email when email cookie is not in the poll') {
      # Create a poll but email cookie not in responders.
      page.set_cookie(:email, 'other@example.com')
      poll = create_poll
      visit("/poll/view/#{poll.id}")
      RSpec::Goldens.verify(page, 'poll_email_not_in_poll', full: true)
    }

    it('asks for email when not logged in') {
      poll = create_poll
      visit("/poll/view/#{poll.id}")
      RSpec::Goldens.verify(page, 'poll_email_needed', full: true)
    }

    it('asks for email when responder salt is incorrect') {
      poll = create_poll

      # Visit with improper salt and see login
      visit("/poll/view/#{poll.id}?responder=not_real_salt")
      RSpec::Goldens.verify(page, 'poll_incorrect_responder', full: true)
    }

    it('logs you in when responder salt is in query') {
      current_time = 388341770
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))
      poll = create_poll

      # Visit with salt of proper user
      salt = poll.responder(email: 'a@a').salt
      visit("/poll/view/#{poll.id}?responder=#{salt}")

      # See poll
      expect(page.get_cookie(:email)).to(eq('a@a'))
      verify_poll_page('poll_salt_logged_in')
    }

    it('sends email when valid email given') {
      poll = create_poll
      visit("/poll/view/#{poll.id}")
      fill_in('email', with: 'a@a')
      click_button('Submit')
      RSpec::Goldens.verify(page, 'poll_valid_email_submitted', full: true)
    }

    it('complains when invalid email given') {
      poll = create_poll
      visit("/poll/view/#{poll.id}")
      fill_in('email', with: 'poop@hey')
      click_button('Submit')
      RSpec::Goldens.verify(page, 'poll_invalid_email_submitted', full: true)
    }
  }
}
