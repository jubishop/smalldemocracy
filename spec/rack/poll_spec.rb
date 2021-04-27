require_relative '../../lib/utils/email'
require_relative '../helpers/poll/expectations'

RSpec.describe(Poll, type: :rack_test) {
  include RSpec::PollExpectations

  context('get /create') {
    it('rejects any access without a cookie') {
      get '/poll/create'
      expect_email_not_found_page
    }

    it('shows poll creation form if you have an email cookie') {
      set_cookie(:email, 'test@example.com')
      get '/poll/create'
      expect_create_page
    }
  }

  context('post /create') {
    it('creates a new poll successfully') {
      set_cookie(:email, 'test@example.com')
      post '/poll/create', title: 'title',
                           question: 'question',
                           choices: 'one, two, three',
                           responders: 'test@example.com',
                           expiration: 10**10
      expect(last_response.redirect?).to(be(true))
      follow_redirect!
      expect_view_page
    }

    it('rejects any post without a cookie') {
      post '/poll/create'
      expect_email_not_found_page
    }

    it('fails if any fields are empty or missing') {
      set_cookie(:email, 'test@example.com')
      post '/poll/create', title: 'title'
      expect(last_response.status).to(be(406))

      post '/poll/create', title: 'title',
                           question: 'question',
                           choices: '',
                           responders: '',
                           expiration: 1
      expect(last_response.status).to(be(406))
    }
  }

  context('get /view') {
    it('shows poll not found') {
      get 'poll/view/does_not_exist'
      expect_not_found_page
    }

    it('shows results if the poll is finished') {
      poll = create_poll(expiration: Time.now.to_i - 1)
      get poll.url
      expect_finished_page
    }

    it('asks for email if responder param is not in poll') {
      poll = create_poll
      get poll.url('not_in_poll')
      expect_email_get_page
    }

    it('stores cookie if responder is in poll') {
      poll = create_poll
      get poll.responders.first.url
      expect(last_response.redirect?).to(be(true))
      expect(get_cookie(:email)).to(eq('a@a'))
      follow_redirect!
      expect_view_page
    }

    it('asks for email if not logged in and no responder param') {
      poll = create_poll
      get poll.url
      expect_email_get_page
    }

    it('asks for email if logged in but not in this poll') {
      set_cookie(:email, 'b@b')
      poll = create_poll
      get poll.url
      expect_email_get_page
    }

    it('shows poll if you have not responded to it yet') {
      set_cookie(:email, 'a@a')
      poll = create_poll
      get poll.url
      expect_view_page
    }

    it('shows your answers if you have already responded') {
      set_cookie(:email, 'a@a')
      poll = create_poll
      poll.mock_response

      get poll.url
      expect_responded_page
    }
  }

  context('post /send') {
    it('sends email successfully') {
      poll = create_poll
      expect(Utils::Email).to(receive(:email)).with(
          poll, poll.responders.first)
      post "/poll/send?poll_id=#{poll.id}&email=a@a"
      expect_email_sent_page
    }

    it('rejects sending to nonexistent poll') {
      post '/poll/send'
      expect(last_response.status).to(be(400))

      post '/poll/send?poll_id=does_not_exist'
      expect_not_found_page
    }

    it('rejects sending to an email not in the response list') {
      poll = create_poll
      post "/poll/send?poll_id=#{poll.id}"
      expect(last_response.status).to(be(400))

      post "/poll/send?poll_id=#{poll.id}&email=does_not_exist"
      expect_email_not_found_page
    }
  }

  context('post /respond') {
    it('saves posted results successfully') {
      poll = create_poll
      data = {
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: poll.choices.map(&:id)
      }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(201))

      allow(Time).to(receive(:now).and_return(Time.at(10**10)))
      expect(poll.results.map(&:text)).to(eq(poll.choices.map(&:text)))
    }

    it('rejects posting to an already responded poll') {
      poll = create_poll
      responder, responses = poll.mock_response

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
      data = { poll_id: poll.id, responder: poll.responders.first.salt }
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(400))

      data[:responses] = [1, 2]
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(406))
    }

    it('rejects posting with duplicate choices') {
      poll = create_poll
      data = {
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: poll.choices.map(&:id),
        expiration: 10**10
      }
      data[:responses][0] = data[:responses][1]
      post '/poll/respond', data.to_json, { CONTENT_TYPE: 'application/json' }
      expect(last_response.status).to(be(409))
    }
  }
}
