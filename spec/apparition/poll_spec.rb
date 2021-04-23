RSpec.describe('/poll', type: :feature) {
  include_context(:apparition)

  def verify_poll_page(filename)
    expect(page).to(have_button(text: 'Submit Choices'))
    RSpec::Goldens.verify(page, filename, full: true)
  end

  context('/create') {
    def create_poll(email:, time: Time.now.to_i + 10)
      visit('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('responders', with: email)
      fill_in('choices', with: 'one, two, three')
      fill_in('expiration', with: time)
      click_button('Submit')
    end

    it('kicks off a full poll lifecycle') {
      current_time = 388341770
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      # Create a poll
      page.set_cookie(:email, 'test@example.com')
      create_poll(email: 'test@example.com', time: current_time + 61)

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

    it('asks for email when not in poll') {
      # Create a poll with different email cookie
      page.set_cookie(:email, 'someoneelse@example.com')
      create_poll(email: 'test@example.com')
      RSpec::Goldens.verify(page, 'poll_email_not_in_poll', full: true)

      # Remove cookie and still see email is needed
      page.delete_cookie(:email)
      refresh
      RSpec::Goldens.verify(page, 'poll_email_needed', full: true)
    }
  }

  context('/view') {
    def create_poll
      return Models::Poll.create_poll(title: 'title',
                                      question: 'question',
                                      expiration: Time.now.to_i + 62,
                                      choices: 'one, two, three',
                                      responders: 'a@a')
    end

    it('logs you in when responder salt is in query') {
      current_time = 388341770
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))
      poll = create_poll

      # Visit with salt of proper user
      salt = poll.responder(email: 'a@a').salt
      visit("/poll/view/#{poll.id}?responder=#{salt}")

      # See poll
      verify_poll_page('poll_salt_logged_in')

      # Visit with improper salt and see login
      visit("/poll/view/#{poll.id}?responder=not_real_salt")
      RSpec::Goldens.verify(page, 'poll_incorrect_responder', full: true)
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
