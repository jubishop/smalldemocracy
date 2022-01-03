require 'duration'

require_relative 'shared_examples/entity_flows'

RSpec.describe(Poll, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }

  let(:entity) { create_poll }
  it_has_behavior('entity flows', 'poll')

  context('no group') {
    it('displays a modal and redirects you') {
      set_cookie(:email, email)
      visit('/poll/create')
      expect(find('#group-modal')).to(
          have_link('Create Group', href: '/group/create'))
      goldens.verify('no_group_modal')
    }
  }

  context('create') {
    it('creates a poll with complex :choices creation') {
      current_time = Time.new(1982, 6, 6, 11, 30)
      freeze_time(current_time)
      allow_any_instance_of(Array).to(receive(:shuffle, &:to_a))

      # Set up basic data and fields of a new poll.
      email = 'poll_complex_choices@create'
      set_cookie(:email, email)
      create_group(email: email, name: 'poll/create')
      visit('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('expiration', with: current_time + 1.minute)
      select('Borda Split', from: 'type')

      # Sometimes click Add button, sometimes press enter on input field.
      click_button('Add Choice')
      %w[zero one two three four five six].each_with_index { |choice, index|
        if index.even?
          all('input.text').last.fill_in(with: choice)
          click_button('Add Choice')
        else
          all('input.text').last.fill_in(with: "#{choice}\n")
        end
      }

      # Delete last empty field and "two".
      all('li.listable div').last.click
      all('li.listable div')[2].click

      # Ensure clicking Add button and pressing enter do nothing when there's
      # already an empty field.
      all('input.text')[1].fill_in(with: '')
      click_button('Add Choice')
      all('input.text')[4].native.send_keys(:enter)

      # Replace the now empty field ("one") with "seven".
      all('input.text')[1].fill_in(with: 'seven')

      find('h1').click
      goldens.verify('create')

      click_button('Create Poll')
      expect(current_path).to(match(%r{/poll/view/.+}))
    }
  }

  #   def create_choices(choices)
  #   end

  #   def drag_to_bottom(choice)
  #     expect(page).to(have_fontawesome)
  #     expect(page).to(have_button(text: 'Submit Choices'))
  #     choice_node = find(
  #         :xpath,
  #         "//li[@class='choice' and ./p[normalize-space()='#{choice}']]")
  #     choice_node.drag_to(find('ul#bottom-choices'))
  #   end

  #   def rearrange_choices(order)
  #     expect(page).to(have_fontawesome)
  #     expect(page).to(have_button(text: 'Submit Choices'))
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
}
