require_relative 'shared_examples/entity_guards'

RSpec.describe(Group, type: :rack_test) {
  let(:group) { create_group }
  let(:email) { group.email }
  let(:members) { ['one@one', 'two@two', 'three@three'] }
  let(:valid_params) {
    {
      name: 'name',
      members: members
    }
  }

  let(:entity) { create_group(email: email) }
  it_has_behavior('rack entity guards', 'group')

  context('get /create') {
    it('shows creation page if you have an email cookie') {
      expect_slim('group/create', email: email)
      get 'group/create'
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    let(:email) { random_email }

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
    let(:email) { member.email }
    let(:member) { group.add_member }

    it('shows group for member') {
      expect_slim('group/view', group: group, member: member)
      get group.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows not found for non member') {
      set_cookie(:email, create_user.email)
      expect_slim('group/not_found')
      get group.url
      expect(last_response.status).to(be(404))
    }
  }

  shared_examples('group mutability') { |operation|
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
  }

  shared_examples('creator mutability') { |operation|
    it_has_behavior('group mutability', operation)

    it('fails if user is not group creator') {
      email = group.add_member.email
      set_cookie(:email, email)
      post "group/#{operation}", valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("#{email} is not the creator of #{group.name}"))
    }
  }

  shared_context('mutable group') {
    let(:member_email) { 'mutable_member@group.com' }
    let(:valid_params) {
      {
        hash_id: group.hashid,
        email: member_email
      }
    }
  }

  context('post /add_member') {
    include_context('mutable group')

    it_has_behavior('creator mutability', 'add_member')

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
    include_context('mutable group')

    before(:each) {
      group.add_member(email: member_email)
    }

    it_has_behavior('creator mutability', 'remove_member')

    it('removes member from group') {
      expect(group.members.map(&:email)).to(
          match_array([group.creating_member.email, member_email]))
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

  context('post /name') {
    let(:group_name) { 'New Group Name' }
    let(:valid_params) {
      {
        hash_id: group.hashid,
        name: group_name
      }
    }

    it_has_behavior('creator mutability', 'name')

    it('updates group name') {
      expect(group.name).to_not(eq(group_name))
      post 'group/name', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Group name changed'))
      expect(group.reload.name).to(eq(group_name))
    }
  }

  context('post /destroy') {
    let(:valid_params) { { hash_id: group.hashid } }

    it_has_behavior('creator mutability', 'destroy')

    it('destroys a group') {
      post '/group/destroy', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Group destroyed'))
      expect(group.exists?).to(be(false))
    }
  }

  context('post /leave') {
    let(:valid_params) { { hash_id: group.hashid } }

    it_has_behavior('group mutability', 'leave')

    it('leaves group') {
      member = group.add_member
      expect(group.members).to(include(member))
      set_cookie(:email, member.email)
      post '/group/leave', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Group left'))
      expect(group.members(reload: true)).to_not(include(member))
      expect(member.exists?).to(be(false))
    }

    it('rejects leaving a group you are not a part of') {
      email = random_email
      set_cookie(:email, email)
      post '/group/leave', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("#{email} is not a member of #{group.name}"))
    }

    it('rejects leaving a group you created') {
      post '/group/leave', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('Creators cannot leave their own group'))
    }
  }
}
