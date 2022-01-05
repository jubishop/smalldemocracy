require 'duration'

require_relative 'shared_examples/entity_flows'

RSpec.describe(Poll, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }

  let(:entity) { create_poll }
  it_has_behavior('entity flows')

  context('create') {
    it('creates a poll with complex :choices creation') {
      # Set up basic data and fields of a new poll.
      email = 'poll_complex_choices@create'
      set_cookie(:email, email)
      group = create_group(email: email, name: 'poll/create')
      go('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('expiration', with: Time.new(2032, 6, 6, 11, 30))
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

      # Click on title to remove focus from any form input.
      find('h1').click
      goldens.verify('create')

      # Confirm redirect to viewing poll after creation.
      expect_slim(
          'poll/view',
          poll: an_instance_of(Models::Poll),
          member: group.creating_member,
          timezone: an_instance_of(TZInfo::DataTimezone))
      click_button('Create Poll')
    }

    it('displays a modal and redirects you when you have no group') {
      set_cookie(:email, email)
      go('/poll/create')
      expect(find('#group-modal')).to(
          have_link('Create Group', href: '/group/create'))
      goldens.verify('no_group_modal')
    }

    it('uses group_id to select a specific group option') {
      user = create_user
      set_cookie(:email, user.email)
      5.times { user.add_group }
      group = user.add_group(name: 'special group')
      go("/poll/create?group_id=#{group.id}")
      goldens.verify('create_specific_group')
    }
  }

  context(:borda) {
    before(:each) {
      freeze_time(Time.new(1982, 6, 6, 11, 30))
      allow_any_instance_of(Array).to(receive(:shuffle, &:to_a))
    }

    def wait_for_sortable
      expect(page).to(have_button(text: 'Submit Choices'))
    end

    def rearrange_choices(order)
      wait_for_sortable
      values = page.evaluate_script('Poll.sortable.toArray()')
      expect(values.length).to(be(order.length))
      expect(order.uniq.length).to(be(order.length))
      expect(order.uniq.sort.max).to(be(order.length - 1))
      values = order.map { |position| values[position] }
      page.execute_script("Poll.sortable.sort(#{values})")
      page.execute_script('Poll.updateScores()')
    end

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

    context(:borda_split) {
      def drag_to_bottom(choice)
        wait_for_sortable
        choice_node = find(
            :xpath,
            "//li[@class='choice' and ./p[normalize-space()='#{choice}']]")
        choice_node.drag_to(find('ul#bottom-choices'))
      end

      it('submits a borda split poll response') {
        # Set up and visit basic poll already in DB.
        poll = create_poll(email: 'view@bordasplit',
                           title: 'borda_split_title',
                           question: 'borda_split_question',
                           type: :borda_split)
        %w[one two three four five six].each { |choice|
          poll.add_choice(text: choice)
        }
        set_cookie(:email, poll.email)
        go(poll.url)

        # Get a screenshot with an empty bottom section
        goldens.verify('view_borda_split_empty_bottom')

        # Drag a couple choices to the bottom red section.
        drag_to_bottom('two')
        drag_to_bottom('three')

        # Rearrange our remaining selected choices.
        rearrange_choices([1, 0, 3, 2])
        wait_for_sortable

        # Click on title to remove focus from any form input.
        find('h1').click
        goldens.verify('view_borda_split')

        # Confirm reload to viewing poll after responding.
        expect_slim(
            'poll/responded',
            poll: poll,
            member: poll.creating_member,
            timezone: an_instance_of(TZInfo::DataTimezone))
        click_button('Submit Choices')
      }
    }
  }

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
