RSpec.describe('/poll', type: :feature) {
  include_context(:capybara)

  context('get /create') {
    it('rejects any access without a cookie') {
      get '/poll/create'
      expect(last_response.ok?).to(be(false))
      expect(last_response.body).to(have_content('Email Not Found'))
    }

    it('shows poll creation form if you have an email cookie') {
      set_cookie(:email, 'test@example.com')
      get '/poll/create'
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(
          have_selector('form[action="/poll/create"][method=post]'))
      expect(last_response.body).to(have_selector('input[type=submit]'))
    }
  }

  context('post /create') {
    it('rejects any post without a cookie') {
      post '/poll/create'
      expect(last_response.ok?).to(be(false))
      expect(last_response.body).to(have_content('Email Not Found'))
    }

    it('creates a new poll successfully') {
      set_cookie(:email, 'test@example.com')
      post '/poll/create', title: 'title',
                           question: 'question',
                           choices: 'one, two, three',
                           responders: 'test@example.com',
                           expiration: 10**10
      expect(last_response.redirect?).to(be(true))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_selector('ul#choices'))
    }

    it('fails if any fields are empty or missing') {
      set_cookie(:email, 'test@example.com')
      post '/poll/create', title: 'title'
      expect(last_response.status).to(be(406))

      post '/poll/create', title: 'title',
                           question: 'question',
                           choices: '',
                           responders: '',
                           expiration: 0
      expect(last_response.status).to(be(406))
    }
  }

  context('post /respond') {
    def create_poll
      return Models::Poll.create_poll(title: 'title',
                                      question: 'question',
                                      expiration: Time.now.to_i + 62,
                                      choices: 'one, two, three',
                                      responders: 'a@a')
    end

    it('successfully saves posted results') {
      poll = create_poll
      data = {
        poll_id: poll.id,
        responder: poll.responder(email: 'a@a').salt,
        responses: poll.choices.map(&:id)
      }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(201))

      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      expect(poll.results.map(&:text)).to(eq(poll.choices.map(&:text)))
    }

    it('rejects posting to an already responded poll') {
      poll = create_poll
      responder = poll.responder(email: 'a@a')
      responses = poll.choices.map(&:id)
      responses.each_with_index { |choice_id, rank|
        responder.add_response(choice_id: choice_id, rank: rank)
      }

      data = {
        poll_id: poll.id,
        responder: responder.salt,
        responses: responses
      }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(409))
    }

    it('rejects an empty post body') {
      post '/poll/respond'
      expect(last_response.status).to(be(400))
    }

    it('rejects posting to nonexistent poll') {
      data = {}
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(400))

      data = { poll_id: 'does not exist' }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(404))
    }

    it('rejects posting with invalid responder') {
      poll = create_poll
      data = { poll_id: poll.id }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(400))

      data[:responder] = 'does not exist'
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(404))
    }

    it('rejects posting with invalid responses') {
      poll = create_poll
      data = { poll_id: poll.id, responder: poll.responder(email: 'a@a').salt }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(400))

      data[:responses] = [1, 2]
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(406))
    }
  }
}
