require 'duration'

require_relative 'shared_examples/entity_flows'

RSpec.describe(Poll, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }
  let(:time) {
    Time.new(1982, 6, 6, 11, 30, 0, TZInfo::Timezone.get('America/Los_Angeles'))
  }

  let(:entity) { create_poll }
  it_has_behavior('entity flows')

  context(:create) {
    it('creates a poll with complex :choices creation') {
      # Set up basic data and fields of a new poll.
      email = 'poll_complex_choices@create'
      set_cookie(:email, email)
      group = create_group(email: email, name: 'poll/create')
      go('/poll/create')
      goldens.verify('create_empty')
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
      goldens.verify('create_no_group_modal')
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

  context(:view) {
    let(:poll) {
      create_poll(email: "#{type}@view.com",
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:member) { poll.creating_member }

    def expect_responded_slim
      expect_slim(
          'poll/responded',
          poll: poll,
          member: member,
          timezone: an_instance_of(TZInfo::DataTimezone))
    end

    before(:each) {
      freeze_time(time)
      allow_any_instance_of(Array).to(receive(:shuffle, &:to_a))
      set_cookie(:email, poll.email)
      %w[zero one two three four five six].each { |choice|
        poll.add_choice(text: choice)
      }
    }

    context(:borda) {
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

      context(:borda_single) {
        let(:type) { :borda_single }

        it('submits a poll response') {
          go(poll.url)

          # Rearrange our choices.
          rearrange_choices([1, 0, 6, 3, 2, 5, 4])
          wait_for_sortable

          # Click on title to remove focus from any form input.
          find('h1').click
          goldens.verify('view_borda_single')

          # Confirm reload to viewing poll after responding.
          expect_responded_slim
          click_button('Submit Choices')
        }
      }

      context(:borda_split) {
        let(:type) { :borda_split }

        def drag_to_bottom(choice)
          wait_for_sortable
          choice_node = find(
              :xpath,
              "//li[@class='choice' and ./p[normalize-space()='#{choice}']]")
          choice_node.drag_to(find('ul#bottom-choices'))
        end

        it('submits a poll response') {
          go(poll.url)

          # Get a screenshot with an empty bottom section
          goldens.verify('view_borda_split_empty_bottom')

          # Drag a couple choices to the bottom red section.
          drag_to_bottom('two')
          drag_to_bottom('three')

          # Rearrange our remaining selected choices.
          rearrange_choices([1, 4, 0, 3, 2])
          wait_for_sortable

          # Click on title to remove focus from any form input.
          find('h1').click
          goldens.verify('view_borda_split')

          # Confirm reload to viewing poll after responding.
          expect_responded_slim
          click_button('Submit Choices')
        }
      }
    }

    context(:choose) {
      let(:type) { :choose_one }

      it('submits a poll response') {
        go(poll.url)

        # Get a screenshot of all our choices.
        goldens.verify('view_choose')

        # Confirm reload to viewing poll after responding.
        expect_responded_slim
        click_button('three')
      }
    }
  }

  context(:responded) {
    let(:poll) {
      create_poll(email: "#{type}@responded.com",
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:member) { poll.creating_member }

    before(:each) {
      freeze_time(time)
      set_cookie(:email, poll.email)
      %w[zero one two three four five six].each { |choice|
        poll.add_choice(text: choice)
      }
    }

    shared_examples('borda response') {
      it('shows a responded page') {
        choices.each_with_index { |position, rank|
          choice = poll.choices[position]
          member.add_response(choice_id: choice.id,
                              score: score_calculation.call(rank))
        }
        go(poll.url)
        goldens.verify("responded_#{type}")
      }
    }

    context(:borda_single) {
      let(:type) { :borda_single }
      let(:choices) { [3, 5, 1, 2, 0, 4, 6] }
      let(:score_calculation) {
        ->(rank) { poll.choices.length - rank - 1 }
      }

      it_has_behavior('borda response')
    }

    context(:borda_split) {
      let(:type) { :borda_split }
      let(:choices) { [3, 5, 1, 6] }
      let(:score_calculation) {
        ->(rank) { poll.choices.length - rank }
      }

      it_has_behavior('borda response')
    }

    context(:choose) {
      let(:type) { :choose_one }
      let(:choice) { poll.choices[3] }

      it('shows a responded page') {
        member.add_response(choice_id: choice.id)
        go(poll.url)
        goldens.verify('responded_choose')
      }
    }
  }

  context(:finished) {
    let(:poll) {
      create_poll(email: "#{type}@finished.com",
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:group) {
      poll.group
    }
    let(:members) {
      Array.new(6).fill { |i|
        group.add_member(email: "#{type}_#{i}@finished.com")
      }
    }
    let(:choices) {
      %w[zero one two three four five six].to_h { |choice|
        [choice, poll.add_choice(text: choice)]
      }
    }

    before(:each) {
      freeze_time(time)
      set_cookie(:email, poll.email)
    }

    shared_examples('finish') {
      it('shows a finished page') {
        responses.each_with_index { |ranked_choices, index|
          member = members[index]
          ranked_choices.each_with_index { |choice, rank|
            member.add_response(
                choice_id: choices[choice].id,
                score: score_calculation.call(rank))
          }
        }
        poll.update(expiration: past)
        go(poll.url)
        goldens.verify("finished_#{type}")
        summary_expansions.each { |summary_pos|
          all('summary')[summary_pos].click
        }
        goldens.verify("finished_#{type}_expanded")
      }
    }

    context(:borda_single) {
      let(:type) { :borda_single }
      let(:responses) {
        [
          %w[zero one two three four five six],
          %w[five six zero one two three four],
          %w[five six zero three four one two],
          %w[five three four six zero one two],
          %w[two five three four six zero one]
        ]
      }
      let(:score_calculation) {
        ->(rank) { poll.choices.length - rank - 1 }
      }
      let(:summary_expansions) { [1, 3] }

      it_has_behavior('finish')
    }

    context(:borda_split) {
      let(:type) { :borda_split }
      let(:responses) {
        [
          %w[zero one two three],
          %w[five six zero one two],
          %w[five six zero],
          %w[five three four six zero one],
          %w[zero one]
        ]
      }
      let(:score_calculation) {
        ->(rank) { poll.choices.length - rank }
      }
      let(:summary_expansions) { [2, 8] }

      it_has_behavior('finish')
    }

    context(:choose) {
      let(:type) { :choose_one }
      let(:responses) {
        [
          %w[zero],
          %w[two],
          %w[two],
          %w[five],
          %w[zero]
        ]
      }
      let(:score_calculation) { ->(_) {} }
      let(:summary_expansions) { [1] }

      it_has_behavior('finish')
    }
  }
}
