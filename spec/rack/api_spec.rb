RSpec.describe(API, type: :rack_test) {
  shared_examples('api authentication') { |endpoint|
    it('rejects any post without an api key') {
      post endpoint
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('No key given'))
    }

    it('rejects any post with an invalid api key') {
      post endpoint, key: 'my_key'
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('Invalid key given: "my_key"'))
    }
  }

  context('get /api') {
    it('shows api page') {
      expect_slim(:api, user: create_user(email: email))
      get '/api'
      expect(last_response.ok?).to(be(true))
    }

    it('redirects and asks for email with no cookie') {
      clear_cookies
      get '/api'
      expect(last_response.redirect?).to(be(true))
      expect_slim(:logged_out, req: an_instance_of(Tony::Request))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /api/key/new') {
    it('rejects posting if you are not logged in') {
      clear_cookies
      post '/api/key/new'
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('updates api_key successfully') {
      user = create_user(email: email)
      old_api_key = user.api_key
      expect(old_api_key.length).to(be(24))
      post '/api/key/new'
      new_api_key = user.reload.api_key
      expect(new_api_key.length).to(be(24))
      expect(new_api_key).not_to(eq(old_api_key))
    }
  }

  context('post /api/poll/new') {
    it_has_behavior('api authentication', '/api/poll/new')
  }
}
