require 'duration'

RSpec.describe(Poll, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }
  let(:current_time) { Time.new(1982, 6, 6, 11, 30) }

  # context('poll lifecycles') {
  #   before(:each) {
  #     freeze_time(current_time)

  #     # Deterministic choice ordering
  #     allow_any_instance_of(Models::Poll).to(receive(:shuffled_choices) { |poll|
  #       poll.choices.sort_by(&:text)
  #     })

  #     # Create a poll
  #     set_cookie(:email, 'one@one')
  #     visit('/poll/create')
  #     fill_in('title', with: 'this is my title')
  #     fill_in('question', with: 'what is life')
  #     fill_in('choices', with: 'one, two, three, four, five, six')
  #     fill_in('expiration', with: current_time + 1.minute)
  #   }

  #   def create_choices(choices)
  #   end

  #   def drag_to_bottom(choice)
  #     expect(page).to(have_fontawesome)
  #     expect(page).to(have_sortable_js)
  #     choice_node = find(
  #         :xpath,
  #         "//li[@class='choice' and ./p[normalize-space()='#{choice}']]")
  #     choice_node.drag_to(find('ul#bottom-choices'))
  #   end

  #   def rearrange_choices(order)
  #     expect(page).to(have_fontawesome)
  #     expect(page).to(have_sortable_js)
  #     values = page.evaluate_script('Poll.sortable.toArray()')
  #     expect(values.length).to(be(order.length))
  #     expect(order.uniq.length).to(be(order.length))
  #     expect(order.uniq.sort.max).to(be(order.length - 1))
  #     values = order.map { |position| values[position] }
  #     page.execute_script("Poll.sortable.sort(#{values})")
  #     page.execute_script('Poll.updateScores()')
  #   end

  #   def submit_creation(page_name)
  #     find('h1').click # Deselect any form field
  #     goldens.verify(page_name)
  #     set_timezone
  #     click_button('Submit')
  #   end

  #   def verify_finished_poll(page_name)
  #     allow(Time).to(receive(:now).and_return(Time.at(10**10)))
  #     refresh_page
  #     goldens.verify(page_name)
  #   end

  #   context('borda') {
  #     def submit_choices(page_name = nil)
  #       expect(page).to(have_fontawesome)
  #       expect(page).to(have_button(text: 'Submit Choices'))
  #       goldens.verify(page_name) if page_name
  #       set_timezone
  #       click_button('Submit Choices')
  #       expect(page).to(have_content('Completed'))
  #     end

  #     it('executes borda_single') {
  #       submit_creation('borda_single_create')
  #       rearrange_choices([4, 2, 0, 5, 3, 1])
  #       submit_choices
  #       set_cookie(:email, 'two@two')
  #       refresh_page
  #       rearrange_choices([5, 3, 2, 0, 4, 1])
  #       submit_choices('borda_single_view')
  #       goldens.verify('borda_single_responded')
  #       verify_finished_poll('borda_single_finished')
  #       all('details')[1].click
  #       all('details')[3].click
  #       goldens.verify('borda_single_details_expanded')
  #     }

  #     it('executes borda_split') {
  #       select('Borda Split', from: 'type')
  #       submit_creation('borda_split_create')
  #       drag_to_bottom('two')
  #       drag_to_bottom('three')
  #       rearrange_choices([1, 0, 3, 2])
  #       expect(page).to(have_button(text: 'Submit Choices'))
  #       submit_choices
  #       set_cookie(:email, 'two@two')
  #       refresh_page
  #       drag_to_bottom('two')
  #       drag_to_bottom('five')
  #       rearrange_choices([3, 1, 0, 2])
  #       submit_choices('borda_split_view')
  #       goldens.verify('borda_split_responded')
  #       verify_finished_poll('borda_split_finished')
  #       all('details')[0].click
  #       all('details')[3].click
  #       goldens.verify('borda_split_details_expanded')
  #     }
  #   }

  #   context('choose') {
  #     def submit_choice(choice)
  #       set_timezone
  #       expect(page).to(have_fontawesome)
  #       click_button(choice)
  #     end

  #     it('executes choose_one') {
  #       select('Choose One', from: 'type')
  #       submit_creation('choose_one_create')
  #       goldens.verify('choose_one_view')
  #       submit_choice('one')
  #       goldens.verify('choose_one_responded')
  #       set_cookie(:email, 'two@two')
  #       refresh_page
  #       submit_choice('two')
  #       set_cookie(:email, 'three@three')
  #       refresh_page
  #       submit_choice('two')
  #       verify_finished_poll('choose_one_finished')
  #       all('details')[0].click
  #       all('details')[1].click
  #       goldens.verify('choose_one_details_expanded')
  #     }
  #   }
  # }

  context('logged out') {
    it('asks for email for create') {
      visit('/poll/create')
      expect(page).to(have_link('Sign in with Google', href: '/poll/create'))
      goldens.verify('create_get_email')
    }

    it('asks for email for view') {
      poll = create_poll
      visit(poll.url)
      expect(page).to(have_link('Sign in with Google', href: poll.url))
      goldens.verify('view_get_email')
    }
  }

  context('not found') {
    it('displays a not found page') {
      visit('/poll/invalid_hash_id')
      goldens.verify('not_found')
    }
  }

  context('no group') {
    it('displays a modal and redirects you if no group') {
      set_cookie(:email, 'me@email')
      visit('/poll/create')
      expect(find('#group-modal')).to(
          have_link('Create Group', href: '/group/create'))
      goldens.verify('no_group_modal')
    }
  }
}
