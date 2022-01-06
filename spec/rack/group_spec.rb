require_relative 'shared_examples/entity_guards'

RSpec.describe(Group, type: :rack_test) {
  let(:members) { ['one@one', 'two@two', 'three@three'] }
  let(:valid_params) {
    {
      name: 'name',
      members: members
    }
  }

  let(:entity) { create_group(email: email) }
  it_has_behavior('entity guards', 'group')

  before(:each) { set_cookie(:email, email) }

  context('get /create') {
    it('shows creation page if you have an email cookie') {
      expect_slim('group/create', email: email)
      get 'group/create'
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    it('creates a new group with members and redirects to view') {
      post '/group/create', valid_params
      expect(last_response.redirect?).to(be(true))
      user = Models::User.find_or_create(email: email)
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
    let(:member) { group.add_member }
    let(:email) { member.email }

    it('shows group for member') {
      expect_slim('group/view', group: group, member: member)
      get group.url
      expect(last_response.ok?).to(be(true))
    }
  }
}
