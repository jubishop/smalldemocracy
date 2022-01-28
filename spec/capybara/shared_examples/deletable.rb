RSpec.shared_examples('deletable') {
  it('shows a deletion confirmation warning upon delete') {
    # Click to delete the entity.
    delete_button.click
    expect(page).to(have_modal)

    # Screenshot deletion modal.
    goldens.verify('delete_modal')

    # Click cancel and confirm modal goes away.
    click_link('Cancel')
    expect(page).to_not(have_modal)
    expect(page).to(have_current_path(entity.edit_url))
  }

  it('supports deleting entity') {
    # Click and confirm deletion of entity
    delete_button.click
    expect(page).to(have_modal)
    expect_any_slim(:logged_in)
    click_link('Do It')

    # Confirm redirection to home and entity deleted.
    expect(page).to(have_current_path('/'))
    expect(entity.exists?).to(be(false))
  }
}
