RSpec.describe(Poll, type: :feature) {
  context('full poll lifecycles') {
    def submit_creation(page_name)
      find('h1').click # Deselect any form field
      RSpec::Goldens.verify(page, page_name, full: true)
      click_button('Submit')
    end

    def submit_choices(page_name)
      expect(page).to(have_fontawesome)
      expect(page).to(have_button(text: 'Submit Choices'))
      RSpec::Goldens.verify(page, page_name, full: true)
      click_button('Submit Choices')
    end

    def verify_finished_poll(page_name)
      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      refresh
      RSpec::Goldens.verify(page, page_name, full: true)
    end

    before(:each) {
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
    }

    it('executes borda_single') {
      submit_creation('poll_borda_single_create')
      submit_choices('poll_borda_single_view')
      RSpec::Goldens.verify(page, 'poll_borda_single_responded', full: true)
      verify_finished_poll('poll_borda_single_finished')
    }

    it('executes borda_split') {
      select('Borda Split', from: 'type')
      submit_creation('poll_borda_split_create')

      # TODO: Drag something to the red box.
      page.first('li.choice').drag_to(page.find_by_id('bottom-choices'))
      submit_choices('poll_borda_split_view')

      RSpec::Goldens.verify(page, 'poll_borda_split_responded', full: true)
      verify_finished_poll('poll_borda_split_finished')
    }
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
