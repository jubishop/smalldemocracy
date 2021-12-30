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
}
