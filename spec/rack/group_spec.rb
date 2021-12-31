require_relative 'shared_examples/entity_guards'

RSpec.describe(Group, type: :rack_test) {
  let(:user) { create_user }
  let(:email) { user.email }
  let(:members) { ['one@one', 'two@two', 'three@three'] }
  let(:valid_params) {
    {
      name: 'name',
      members: members
    }
  }

  let(:entity) { create_group(email: email) }
  it_has_behavior('entity guards', 'group')

  context('get /create') {
    before(:each) { set_cookie(:email, email) }

    it('shows creation page if you have an email cookie') {
      expect_slim('group/create')
      get 'group/create'
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    before(:each) { set_cookie(:email, email) }

    it('creates a new group with members and redirects to view') {
      post_json('/group/create', valid_params)
      expect(last_response.redirect?).to(be(true))
      group = user.groups.first
      expect(group).to(have_attributes(email: user.email, name: 'name'))
      expect(group.members.map(&:email)).to(match_array(members + [user.email]))
      expect_slim('group/view', group: group, member: group.creating_member)
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }
  }

  context('get /view') {
    let(:group) { create_group }

    it('shows group for creator') {
      member = group.creating_member
      set_cookie(:email, member.email)
      expect_slim('group/view', group: group, member: member)
      get group.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows group for member') {
      member = group.add_member
      set_cookie(:email, member.email)
      expect_slim('group/view', group: group, member: member)
      get group.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows group not found if logged in but not in this group') {
      set_cookie(:email, 'me@email')
      expect_slim('group/not_found')
      get group.url
      expect(last_response.status).to(be(404))
    }
  }
}
