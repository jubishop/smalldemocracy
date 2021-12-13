RSpec.describe(Poll, type: :feature) {
  let(:current_time) { 388341770 }
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }

  context('poll lifecycles') {
    before(:each) {
      # It's 1982!
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      # Deterministic choice ordering
      allow_any_instance_of(Models::Poll).to(receive(:shuffled_choices) { |poll|
        poll.choices.sort_by(&:text)
      })

      # Create a poll
      set_cookie(:email, 'one@one')
      visit('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('responders', with: 'one@one, two@two')
      fill_in('choices', with: 'one, two, three')
      fill_in('expiration', with: current_time + 61)
    }

    def drag_to_bottom(choice)
      expect(page).to(have_fontawesome)
      expect(page).to(have_sortable_js)
      choice_node = find(
          :xpath,
          "//li[@class='choice' and ./p[normalize-space()='#{choice}']]")
      choice_node.drag_to(find('ul#bottom-choices'))
    end

    def rearrange_choices(order)
      expect(page).to(have_fontawesome)
      expect(page).to(have_sortable_js)
      values = page.evaluate_script('Poll.sortable.toArray()')
      expect(values.length).to(be(order.length))
      values = order.map { |position| values[position] }
      page.execute_script("Poll.sortable.sort(#{values})")
      page.execute_script('Poll.updateScores()')
    end

    def submit_creation(page_name)
      find('h1').click # Deselect any form field
      goldens.verify(page_name)
      set_timezone
      click_button('Submit')
    end

    def verify_finished_poll(page_name)
      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      refresh_page
      goldens.verify(page_name)
    end

    context('borda') {
      def submit_choices(page_name = nil)
        expect(page).to(have_fontawesome)
        expect(page).to(have_button(text: 'Submit Choices'))
        goldens.verify(page_name) if page_name
        set_timezone
        click_button('Submit Choices')
        expect(page).to(have_content('Completed'))
      end

      it('executes borda_single') {
        submit_creation('borda_single_create')
        rearrange_choices([1, 2, 0])
        submit_choices
        set_cookie(:email, 'two@two')
        refresh_page
        rearrange_choices([2, 0, 1])
        submit_choices('borda_single_view')
        goldens.verify('borda_single_responded')
        verify_finished_poll('borda_single_finished')
        all('label.details')[1].click
        goldens.verify('borda_single_details_expanded')
      }

      it('executes borda_split') {
        select('Borda Split', from: 'type')
        submit_creation('borda_split_create')
        drag_to_bottom('two')
        drag_to_bottom('three')
        expect(page).to(have_button(text: 'Submit Choices'))
        goldens.verify('borda_split_before_input')
        submit_choices
        set_cookie(:email, 'two@two')
        refresh_page
        drag_to_bottom('two')
        rearrange_choices([1, 0])
        submit_choices('borda_split_view')
        goldens.verify('borda_split_responded')
        verify_finished_poll('borda_split_finished')
        all('label.details')[0].click
        all('label.details')[3].click
        goldens.verify('borda_split_details_expanded')
      }
    }

    context('choose') {
      it('executes choose_one') {
        select('Choose One', from: 'type')
        submit_creation('choose_one_create')
        set_timezone
        click_button('one')
        goldens.verify('choose_one_responded')
        verify_finished_poll('choose_one_some_finished')
        allow(Time).to(receive(:now).and_return(Time.at(current_time + 1)))
        set_cookie(:email, 'two@two')
        refresh_page
        click_button('two')
        verify_finished_poll('choose_one_all_finished')
      }
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

    it('fails when creation form is incomplete') {
      set_cookie(:email, 'one@one')
      visit('/poll/create')
      click_button('Submit')
      goldens.verify('poll_form_incomplete', expect_google_fonts: false)
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('poll/blah')
      goldens.verify('page_not_found')
    }
  }
}
