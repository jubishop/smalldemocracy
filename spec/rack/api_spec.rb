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

  context('post /api/poll/create') {
    let(:user) { create_user(email: email) }
    let(:group) { create_group }
    let(:type) { :choose_one }
    let(:expiration) { future }
    let(:choices) { %w[one two three] }
    let(:email) { group.email }
    let(:title) { 'title' }
    let(:question) { 'question' }
    let(:valid_params) {
      {
        key: user.api_key,
        title: title,
        question: question,
        choices: choices,
        group_id: group.id,
        expiration: expiration.to_i,
        type: type
      }
    }

    it_has_behavior('api authentication', '/api/poll/create')

    it('creates a new poll with choices and returns poll id') {
      post '/api/poll/create', valid_params
      expect(last_response.status).to(be(201))

      poll = Models::Poll.with_hashid(last_response.body)
      expect(poll.email).to(eq(user.email))
      expect(poll.group).to(eq(group))
      expect(poll.title).to(eq(title))
      expect(poll.question).to(eq(question))
      expect(poll.expiration).to(eq(expiration))
      expect(poll.type).to(eq(type))
    }

    it('fails if type is invalid') {
      valid_params[:type] = :invalid_type
      post '/api/poll/create', valid_params
      expect(last_response.status).to(be(400))
    }

    it('fails if poll expiration is invalid string') {
      valid_params[:expiration] = 'Sometime tomorrow'
      post '/api/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('Sometime tomorrow is invalid date'))
    }

    it('fails if poll expiration is in the past') {
      valid_params[:expiration] = past.to_i
      post '/api/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to time in the past'))
    }

    it('fails if poll expiration is more than 90 days out') {
      valid_params[:expiration] = (Time.now + 91.days).to_i
      post '/api/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to more than 90 days in the future'))
    }

    it('fails if user is not part of poll group') {
      user = create_user
      valid_params[:key] = user.api_key
      post '/api/poll/create', valid_params
      expect(last_response.body).to(
          eq("Creator #{user.email} is not a member of #{group.name}"))
      expect(last_response.status).to(be(400))
    }
  }
}
