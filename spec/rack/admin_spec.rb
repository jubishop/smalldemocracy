RSpec.describe(Admin, type: :rack_test) {
  context('get /') {
    it('refuses access') {
      get '/admin'
      expect(last_response.status).to(be(401))
    }
  }
}
