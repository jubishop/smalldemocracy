require 'duration'
require 'tzinfo'

require_relative 'shared_examples/deletable'
require_relative 'shared_examples/entity_guards'

RSpec.describe(Poll, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/poll') }
  let(:expiration_time) {
    Time.at(Time.now + 5.days,
            in: TZInfo::Timezone.get(page.driver.cookies['tz'].value))
  }

  let(:entity) { create_poll }
  it_has_behavior('entity guards')

  def have_expiration_text
    return have_content('Jun 06 1982, at 11:25 PM +07')
  end

  def have_edit_link
    return have_link('(Edit this poll)', href: poll.edit_url)
  end

  def have_view_link
    return have_link('(View this poll)', href: poll.url)
  end

  before(:each) {
    # Need a fixed moment in time for consistent goldens.
    freeze_time(Time.new(1982, 6, 6, 11, 30, 0,
                         TZInfo::Timezone.get('America/New_York')))
  }

  context(:create) {
    let(:group) { |context|
      create_group(email: context.full_description.to_email('poll.com'),
                   name: context.description)
    }

    it('shows poll form ready to be filled in') {
      set_cookie(:email, group.email)
      go('/poll/create')

      expect(page).to(have_field('expiration', with: (Time.now + 7.days).form))
      goldens.verify('create_empty')
    }

    it('creates a poll with complex :choices creation') {
      # Fill in basic data for a poll.
      set_cookie(:email, group.email)
      go('/poll/create')
      fill_in('title', with: 'this is my title')
      fill_in('question', with: 'what is life')
      fill_in('expiration', with: expiration_time)
      select('Borda Split', from: 'type')

      # Sometimes click Add button, sometimes press enter on input field, in
      # either case the new input field gets focus.
      click_button('Add Choice')
      %w[zero one two three four five six].each_with_index { |choice, index|
        input_field = all('input.text').last
        expect(input_field).to(have_focus)
        if index.even?
          input_field.fill_in(with: choice)
          click_button('Add Choice')
        else
          input_field.fill_in(with: "#{choice}\n")
        end
      }

      # Delete last empty field and "two".
      all('li.listable div').last.click
      all('li.listable div')[2].click

      # Ensure clicking Add button and pressing enter do nothing when there's
      # already an empty field, and focuses the empty field.
      empty_field = all('input.text')[1]
      empty_field.fill_in(with: '')
      click_button('Add Choice')
      expect(empty_field).to(have_focus)
      all('input.text')[4].native.send_keys(:enter)
      expect(empty_field).to(have_focus)

      # Replace the now empty field ("one") with "seven".
      empty_field.fill_in(with: 'seven')

      # Click on title to remove focus from any form input.
      find('h1').click
      goldens.verify('create_filled_in')

      # Confirm redirect to viewing poll after creation.
      expect_slim('poll/view',
                  poll: an_instance_of(Models::Poll),
                  member: group.creating_member,
                  timezone: an_instance_of(TZInfo::DataTimezone))
      click_button('Create Poll')

      # Ensure actual changes made in DB.
      poll = group.polls.find { |current_poll|
        current_poll.title == 'this is my title'
      }
      expect(poll.title).to(eq('this is my title'))
      expect(poll.question).to(eq('what is life'))
      expect(poll.choices.map(&:text)).to(
          match_array(%w[zero three four five six seven]))
      expect(poll.expiration).to(eq(expiration_time))
      expect(poll.type).to(eq(:borda_split))
    }

    it('displays a modal and redirects you when you have no group') {
      set_cookie(:email, email)
      go('/poll/create')
      expect(find('#group-modal')).to(
          have_link('Create Group', href: '/group/create'))
      expect(page).to(have_modal)
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

  shared_examples('editable guard') {
    it('shows no edit link for normal member') {
      set_cookie(:email, poll.group.add_member.email)
      go(poll.url)
      expect(page).to_not(have_edit_link)
    }
  }

  context(:view) {
    let(:email) { "#{type}@view.com" }
    let(:poll) {
      create_poll(email: email,
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:member) { poll.creating_member }

    def expect_responded_slim
      expect_slim('poll/responded',
                  poll: poll,
                  member: member,
                  timezone: an_instance_of(TZInfo::DataTimezone))
    end

    before(:each) {
      allow_any_instance_of(Array).to(receive(:shuffle, &:to_a))
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

        it_has_behavior('editable guard')

        it('submits a poll response') {
          go(poll.url)
          expect(page).to(have_expiration_text)
          expect(page).to(have_edit_link)

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

        it_has_behavior('editable guard')

        it('shows an empty borda_split page') {
          go(poll.url)
          goldens.verify('view_borda_split_empty_bottom')
        }

        it('submits a poll response') {
          go(poll.url)
          expect(page).to(have_expiration_text)
          expect(page).to(have_edit_link)

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

      it_has_behavior('editable guard')

      it('submits a poll response') {
        go(poll.url)
        expect(page).to(have_expiration_text)
        expect(page).to(have_edit_link)

        # Get a screenshot of all our choices.
        goldens.verify('view_choose')

        # Confirm reload to viewing poll after responding.
        expect_responded_slim
        click_button('three')
      }
    }
  }

  context(:responded) {
    let(:email) { "#{type}@responded.com" }
    let(:poll) {
      create_poll(email: email,
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:member) { poll.creating_member }

    before(:each) {
      %w[zero one two three four five six].each { |choice|
        poll.add_choice(text: choice)
      }
    }

    shared_examples('deletable response') {
      let(:delete_button) { find('#delete-response') }

      it('shows a deletion confirmation warning upon delete') {
        # Click to delete the poll.
        delete_button.click
        expect(page).to(have_modal)

        # Screenshot deletion modal.
        goldens.verify("#{type}_delete_modal")

        # Click cancel and confirm modal goes away.
        click_link('Cancel')
        expect(page).to_not(have_modal)
        expect(page).to(have_current_path(poll.url))
      }

      it('supports deleting poll') {
        # Click and confirm deletion of poll.
        delete_button.click
        expect(page).to(have_modal)
        expect_any_slim('poll/view')
        click_link('Do It')

        # Confirm redirection to view poll and responses deleted.
        expect(page).to(have_current_path(poll.url))
        member = poll.member(email: email)
        expect(poll.responses(member_id: member.id)).to(be_empty)
      }
    }

    shared_examples('borda response') {
      it_has_behavior('editable guard')
      it_has_behavior('deletable response')

      before(:each) {
        choices.each_with_index { |position, rank|
          choice = poll.choices[position]
          member.add_response(choice_id: choice.id,
                              data: { score: score_calculation.call(rank) })
        }
        go(poll.url)
      }

      it('shows a responded page') {
        expect(page).to(have_expiration_text)
        expect(page).to(have_edit_link)
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

      it_has_behavior('editable guard')
      it_has_behavior('deletable response')

      before(:each) {
        member.add_response(choice_id: choice.id)
        go(poll.url)
      }

      it('shows a responded page') {
        expect(page).to(have_expiration_text)
        expect(page).to(have_edit_link)
        goldens.verify('responded_choose')
      }
    }
  }

  context(:finished) {
    let(:email) { "#{type}@finished.com" }
    let(:poll) {
      create_poll(email: email,
                  title: "#{type}_title",
                  question: "#{type}_question",
                  type: type)
    }
    let(:group) { poll.group }
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

    shared_examples('finish') {
      it_has_behavior('editable guard')

      before(:each) {
        responses.each_with_index { |ranked_choices, index|
          member = members[index]
          ranked_choices.each_with_index { |choice, rank|
            member.add_response(
                choice_id: choices[choice].id,
                data: { score: score_calculation.call(rank) })
          }
        }
        freeze_time(future + 1.day)
        go(poll.url)
        expect(page).to(have_expiration_text)
        expect(page).to(have_edit_link)
      }

      it('shows a finished page') {
        goldens.verify("finished_#{type}")
      }

      it('shows a finished page with expanded summaries') {
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

  context(:edit) {
    let(:email) { |context| context.full_description.to_email('poll.com') }
    let(:poll) { |context|
      create_poll(email: email,
                  title: context.description,
                  question: 'poll question')
    }

    before(:each) {
      10.times { |i| poll.add_choice(text: "choice_#{i}") }
    }

    context('no responses') {
      before(:each) { go(poll.edit_url) }

      let(:entity) { poll }
      let(:delete_button) { find('#delete-poll') }
      it_has_behavior('deletable', 'no_responses')

      it('shows a poll fully free to edit') {
        expect(page).to(have_view_link)
        goldens.verify('edit_no_responses')
      }

      it('supports complete editing of poll') {
        # Change title.
        edit_title_button = find('#edit-title-button')
        edit_title_button.click
        expect(edit_title_button).to(be_gone)
        input_field = find('#poll-title input')
        expect(input_field).to(have_focus)
        input_field.fill_in(with: "New poll title\n")
        sleep(10)
        expect(input_field).to(be_gone)
        expect(edit_title_button).to(be_visible)

        # Change question
        edit_question_button = find('#edit-question-button')
        edit_question_button.click
        expect(edit_question_button).to(be_gone)
        input_field = find('#poll-question input')
        expect(input_field).to(have_focus)
        input_field.fill_in(with: "New poll question\n")
        expect(input_field).to(be_gone)
        expect(edit_question_button).to(be_visible)

        # Add a choice.
        add_button = find('#add-choice')
        expect(add_button).to_not(be_disabled)
        add_button.click
        expect(add_button).to(be_disabled)
        input_field = find('input.input')
        expect(input_field).to(have_focus)
        input_field.fill_in(with: "New poll choice\n")
        expect(input_field).to(be_gone)
        expect(add_button).to_not(be_disabled)

        # Delete choice #2.
        delete_choice_2_button = all('.delete-icon')[2]
        delete_choice_2_button.click
        expect(delete_choice_2_button).to(be_gone)

        # Edit expiration
        fill_in('expiration', with: expiration_time)
        find('#update-expiration').click

        # Screenshot poll's new state.
        goldens.verify('edit_no_responses_modified')

        # Ensure actual changes made in DB.
        expect(poll.reload.title).to(eq('New poll title'))
        expect(poll.reload.question).to(eq('New poll question'))
        poll_choices = poll.choices.map(&:text)
        expect(poll_choices).to(include('New poll choice'))
        expect(poll_choices).to_not(include('choice_2'))
        expect(poll.reload.expiration).to(eq(expiration_time))
      }
    }

    context('with responses') {
      before(:each) {
        poll.choices.each { |choice|
          choice.add_response(member_id: poll.members.sample.id)
        }
        go(poll.edit_url)
      }

      let(:entity) { poll }
      let(:delete_button) { find('#delete-poll') }
      it_has_behavior('deletable', 'with_responses')

      it('shows a poll with limited editability') {
        expect(page).to(have_view_link)
        goldens.verify('edit_with_responses')
      }

      it('supports limited editing of poll') {
        # Cannot change title.
        expect(page).to_not(have_selector('#edit-title-button'))

        # Cannot change question.
        expect(page).to_not(have_selector('#edit-question-button'))

        # Cannot add a choice.
        expect(page).to_not(have_selector('#add-choice'))

        # Cannot delete choice.
        expect(page).to_not(have_selector('li .editable'))

        # Edit expiration
        fill_in('expiration', with: expiration_time)
        find('#update-expiration').click

        # Screenshot poll's new state.
        goldens.verify('edit_with_responses_modified')

        # Ensure expiration change made in DB
        expect(poll.reload.expiration).to(eq(expiration_time))
      }
    }
  }
}
