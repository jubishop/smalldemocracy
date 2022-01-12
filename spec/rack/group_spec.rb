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

  shared_examples('group membership mutability') { |operation|
    it('fails with no cookie') {
      clear_cookies
      post "group/#{operation}", valid_params
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('fails if any field is missing or empty') {
      valid_params.each_key { |key|
        params = valid_params.clone
        params[key] = ''
        post "/group/#{operation}", params
        expect(last_response.status).to(be(400))
        params.delete(key)
        post "/group/#{operation}", params
        expect(last_response.status).to(be(400))
      }
    }

    it('fails if user is not group creator') {
      email = group.add_member.email
      set_cookie(:email, email)
      post "group/#{operation}", valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("#{email} is not the creator of #{group.name}"))
    }
  }

  context('post /add_member') {
    let(:group) { create_group }
    let(:member_email) { 'add_member@group.com' }
    let(:email) { group.email }
    let(:valid_params) {
      {
        hash_id: group.hashid,
        email: member_email
      }
    }

    it_has_behavior('group membership mutability', 'add_member')

    it('adds member to group') {
      expect(group.members).to(eq([group.creating_member]))
      post 'group/add_member', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Group member added'))
      expect(group.members(reload: true).map(&:email)).to(
          match_array([group.creating_member.email, member_email]))
    }

    it('rejects adding member that is already in the group') {
      valid_params[:email] = email
      post 'group/add_member', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          match(/violates unique constraint "member_unique"/))
    }
  }

  context('post /remove_member') {
    let(:group) { create_group }
    let(:email) { group.email }
    let(:member) { group.add_member }
    let(:valid_params) {
      {
        hash_id: group.hashid,
        email: member.email
      }
    }

    it_has_behavior('group membership mutability', 'remove_member')

    it('removes member from group') {
      expect(group.members).to(match_array([group.creating_member, member]))
      valid_params
      post 'group/remove_member', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Group member removed'))
      expect(group.members(reload: true)).to(eq([group.creating_member]))
    }

    it('rejects removing creating member from group') {
      valid_params[:email] = group.email
      post 'group/remove_member', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('Cannot remove the creator of a group'))
    }

    it('rejects removing member that is not in the group') {
      valid_params[:email] = 'remove_member@group.com'
      post 'group/remove_member', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("remove_member@group.com is not a member of #{group.name}"))
    }
  }
}
