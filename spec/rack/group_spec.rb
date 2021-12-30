RSpec.describe(Poll, type: :rack_test) {
  context('get /create') {
    it('requests email if you have no cookie') {
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      get '/group/create'
      expect(last_response.status).to(be(401))
    }

    it('shows group creation page if you have an email cookie') {
      set_cookie(:email, 'my@email')
      expect_slim('group/create')
      get '/group/create'
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    let(:user) { create_user }
    let(:members) { ['one@one', 'two@two', 'three@three'] }
    let(:valid_params) {
      {
        name: 'name',
        members: members
      }
    }
    let(:group) { user.groups.first }

    before(:each) { set_cookie(:email, user.email) }

    it('creates a new poll with choices and redirects to view') {
      post_json('/group/create', valid_params)
      expect(last_response.redirect?).to(be(true))
      puts user.groups
      puts user
      expect(group).to(have_attributes(email: user.email, name: 'name'))
      expect(group.members.map(&:email)).to(match_array(members + [user.email]))
      # expect_slim('group/view', group: group, member: member)
      # follow_redirect!
      # expect(last_response.ok?).to(be(true))
    }
  }
}
