RSpec.describe(Poll, type: :feature) {
  let(:current_time) { 388341770 }
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }

  context('full poll lifecycles') {
    def submit_creation(page_name)
      find('h1').click # Deselect any form field
      goldens.verify(page_name)
      click_button('Submit')
    end

    def submit_choices(page_name = nil)
      expect(page).to(have_fontawesome)
      expect(page).to(have_button(text: 'Submit Choices'))
      goldens.verify(page_name) if page_name
      click_button('Submit Choices')
    end

    def verify_finished_poll(page_name)
      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      refresh
      goldens.verify(page_name)
    end

    before(:each) {
      # It's 1982!
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      # Deterministic choice ordering
      allow_any_instance_of(Models::Poll).to(receive(:shuffled_choices) { |poll|
        poll.choices.sort
      })

      # Create a poll
      set_cookie(:email_address, 'one@one')
      visit('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('responders', with: 'one@one, two@two')
      fill_in('choices', with: 'one, two, three')
      fill_in('expiration', with: current_time + 61)
    }

    it('executes borda_single') {
      submit_creation('borda_single_create')
      page.first('li.choice').drag_to(page.all('li.choice').last)
      submit_choices
      set_cookie(:email_address, 'two@two')
      refresh
      page.all('li.choice').last.drag_to(page.first('li.choice'))
      submit_choices('borda_single_view')
      goldens.verify('borda_single_responded')
      verify_finished_poll('borda_single_finished')
      all('label.details')[1].click
      goldens.verify('borda_single_details_expanded')
    }

    it('executes borda_split') {
      select('Borda Split', from: 'type')
      submit_creation('borda_split_create')
      page.first('li.choice').drag_to(page.find_by_id('bottom-choices'))
      submit_choices
      set_cookie(:email_address, 'two@two')
      refresh
      page.all('li.choice')[1].drag_to(page.find_by_id('bottom-choices'))
      submit_choices('borda_split_view')
      goldens.verify('borda_split_responded')
      verify_finished_poll('borda_split_finished')
      all('label.details')[1].click
      all('label.details')[4].click
      goldens.verify('borda_split_details_expanded')
    }

    it('executes choose_one') {
      select('Choose One', from: 'type')
      submit_creation('choose_one_create')
      click_button('one')
      goldens.verify('choose_one_responded')
      verify_finished_poll('choose_one_some_finished')
      allow(Time).to(receive(:now).and_return(Time.at(current_time + 1)))
      set_cookie(:email_address, 'two@two')
      refresh
      click_button('two')
      verify_finished_poll('choose_one_all_finished')
    }
  }

  context('poll') {
    it('blocks create when not logged in') {
      visit('/poll/create')
      goldens.verify('email_not_found')
    }

    it('asks for email') {
      poll = create
      visit(poll.url)
      goldens.verify('email_get')
    }

    it('sends email') {
      poll = create
      visit(poll.url)
      fill_in('email', with: 'a@a')
      click_button('Submit')
      goldens.verify('email_sent')
    }

    it('complains when invalid email given') {
      poll = create
      visit(poll.url)
      fill_in('email', with: 'poop@hey')
      click_button('Submit')
      goldens.verify('email_responder_not_found')
    }

    it('responds when poll not found') {
      visit('/poll/view/does_not_exist')
      goldens.verify('not_found')
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('poll/blah')
      goldens.verify('page_not_found')
    }
  }
}
