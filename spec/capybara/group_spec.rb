require_relative 'shared_examples/deletable'
require_relative 'shared_examples/entity_guards'

RSpec.describe(Group, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/group') }

  let(:entity) { create_group }
  it_has_behavior('entity guards')

  context(:create) {
    let(:email) { 'group@create.com' }

    before(:each) { go('/group/create') }

    it('shows a group create page') {
      goldens.verify('create_empty')
    }

    it('creates a group with complex :members creation') {
      # Fill in a name.
      fill_in('name', with: 'group_create')

      # Add some members.  Sometimes click Add button, sometimes press enter on
      # input field, in either case the new input field gets focus.
      click_button('Add Member')
      6.times { |i|
        input_field = all('input.text').last
        expect(input_field).to(have_focus)
        email = "group_#{i + 1}@create.com"
        if i.even?
          input_field.fill_in(with: email)
          click_button('Add Member')
        else
          input_field.fill_in(with: "#{email}\n")
        end
      }

      # Delete last empty field and "group_two@create.com"
      all('li.listable div').last.click
      all('li.listable div')[2].click

      # Ensure clicking Add button and pressing enter do nothing when there's
      # already an empty field, and focuses the empty field.
      empty_field = all('input.text')[1]
      empty_field.fill_in(with: '')
      click_button('Add Member')
      expect(empty_field).to(have_focus)
      all('input.text')[4].native.send_keys(:enter)
      expect(empty_field).to(have_focus)

      # Ensure clicking Add button and pressing enter when there's an invalid
      # email does nothing, and focuses the invalid field.
      invalid_field = all('input.text')[1]
      invalid_field.fill_in(with: 'invalid')
      click_button('Add Member')
      expect(invalid_field).to(have_focus)
      all('input.text')[4].native.send_keys(:enter)
      expect(invalid_field).to(have_focus)

      # Replace the now invalid field with "group_7".
      invalid_field.fill_in(with: 'group_7@create.com')

      # Click on title to remove focus from any form input.
      find('h1').click
      goldens.verify('create_filled_in')

      # Confirm redirect to viewing group after creation.
      expect_slim(
          'group/view',
          group: an_instance_of(Models::Group),
          member: an_instance_of(Models::Member))
      click_button('Create Group')

      # Ensure actual changes made in DB.
      user = Models::User.find_or_create(email: 'group@create.com')
      expect(user.created_groups.map(&:name)).to(include('group_create'))
    }
  }

  context(:view) {
    let(:group) { |context|
      create_group(email: context.full_description.to_email('group.com'),
                   name: context.description)
    }

    def expect_create_new_poll_link
      expect(page).to(
          have_link("Create new poll for #{group.name}",
                    href: "/poll/create?group_id=#{group.id}"))
    end

    before(:each) {
      10.times { |i|
        group.add_member(email: "group_member_#{i + 1}@view.com")
      }
      go(group.url)
    }

    shared_examples('displayable') { |viewer|
      it('displays a group') {
        expect_create_new_poll_link
        goldens.verify("#{viewer}_view")
      }
    }

    context(:creator) {
      let(:email) { group.email }

      it_has_behavior('displayable', 'creator')

      let(:entity) { group }
      let(:delete_button) { find('#delete-group') }
      it_has_behavior('deletable', 'group')

      it('supports complex editing of group') {
        # Rename group.
        edit_group_button = find('#edit-group-button')
        edit_group_button.click
        expect(edit_group_button).to(be_gone)
        input_field = find('#group-name input')
        expect(input_field).to(have_focus)
        input_field.fill_in(with: "New group name\n")
        expect(input_field).to(be_gone)
        expect(edit_group_button).to(be_visible)

        # Add a member.
        add_button = find('#add-member')
        expect(add_button).to_not(be_disabled)
        add_button.click
        expect(add_button).to(be_disabled)
        input_field = find('input.input')
        expect(input_field).to(have_focus)
        input_field.fill_in(with: "group_adder@view.com\n")
        expect(input_field).to(be_gone)
        expect(add_button).to_not(be_disabled)

        # The first delete button is the creator, and ignores clicks.
        first('.delete-icon').click

        # Delete member #2.
        delete_member_2_button = all('.delete-icon')[2]
        delete_member_2_button.click
        expect(delete_member_2_button).to(be_gone)

        # Screenshot group's new state.
        goldens.verify('view_modified')

        # Ensure actual changes made in DB.
        expect(group.reload.name).to(eq('New group name'))
        member_emails = group.members.map(&:email)
        expect(member_emails).to(include('group_adder@view.com'))
        expect(member_emails).to_not(include('group_creator_2@view.com'))
      }
    }

    context(:member) {
      let(:email) { 'group_member_9@view.com' }

      it_has_behavior('displayable', 'member')

      it('shows a confirmation warning upon leaving') {
        # Click to leave the group.
        leave_group_button = find('#leave-group')
        leave_group_button.click
        expect(page).to(have_modal)

        # Screenshot group deletion modal.
        goldens.verify('leave_modal')

        # Click cancel and confirm modal goes away.
        click_link('Cancel')
        expect(page).to_not(have_modal)
        expect(page).to(have_current_path(group.url))
      }

      it('supports leaving group') {
        member = group.member(email: email)
        expect(member.exists?).to(be(true))

        # Click and confirm leaving group.
        leave_group_button = find('#leave-group')
        leave_group_button.click
        expect(page).to(have_modal)
        expect_any_slim(:logged_in)
        click_link('Do It')

        # Confirm redirection to home and group left.
        expect(page).to(have_current_path('/'))
        expect(group.member(email: email)).to(be(nil))
        expect(member.exists?).to(be(false))
      }
    }
  }
}
