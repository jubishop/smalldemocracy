RSpec.shared_examples('entity guards') { |path|
  before(:each) { set_cookie(:email, email) }

  context('get /create') {
    it('requests email if you have no cookie') {
      clear_cookies
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      get "/#{path}/create"
      expect(last_response.status).to(be(401))
    }
  }

  context('post /create') {
    it('rejects any post without a cookie') {
      clear_cookies
      post "/#{path}/create", valid_params
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('fails if post body is nonexistent') {
      post "#{path}/create"
      expect(last_response.status).to(be(400))
    }

    it('fails if any field is missing or empty') {
      valid_params.each_key { |key|
        params = valid_params.clone
        params[key] = params[key].is_a?(Enumerable) ? [] : ''
        post "/#{path}/create", params
        expect(last_response.status).to(be(400))
        params.delete(key)
        post "/#{path}/create", params
        expect(last_response.status).to(be(400))
      }
    }
  }

  context('get /view') {
    it('shows not found for invalid urls') {
      expect_slim("#{path}/not_found")
      get "#{path}/view/does_not_exist"
      expect(last_response.status).to(be(404))
    }

    it('asks for email if not logged in') {
      clear_cookies
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      get entity.url
      expect(last_response.status).to(be(401))
    }

    it('shows not found if logged in but not a member of this entity') {
      set_cookie(:email, random_email)
      expect_slim("#{path}/not_found")
      get entity.url
      expect(last_response.status).to(be(404))
    }
  }
}
