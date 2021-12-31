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

  it_behaves_like('entity', 'group')

  context('post /create') {
    let(:group) { user.groups.first }

    before(:each) { set_cookie(:email, email) }

    it('creates a new group with members and redirects to view') {
      post_json('/group/create', valid_params)
      expect(last_response.redirect?).to(be(true))
      expect(group).to(have_attributes(email: user.email, name: 'name'))
      expect(group.members.map(&:email)).to(match_array(members + [user.email]))
      expect_slim('group/view', group: group, member: group.creating_member)
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }
  }
}
