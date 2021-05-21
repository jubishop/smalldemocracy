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
      set_cookie(:email_address, 'test@example.com')
      get '/poll/create'
      expect_create_page
    }
  }

  context('post /create') {
    before(:all) {
      @valid_params = {
        title: 'title',
        question: 'question',
        choices: 'one, two, three',
        responders: 'test@example.com',
        expiration: 10**10
      }
    }

    before(:each) {
      set_cookie(:email_address, 'test@example.com')
    }

    it('creates a new :borda_single poll successfully') {
      post '/poll/create', **@valid_params
      expect(last_response.redirect?).to(be(true))
      follow_redirect!
      expect_view_borda_single_page
    }

    it('creates a new :borda_split poll successfully') {
      params = @valid_params.clone
      params[:type] = :borda_split
      post '/poll/create', **params
      expect(last_response.redirect?).to(be(true))
      follow_redirect!
      expect_view_borda_split_page
    }

    it('rejects any post without a cookie') {
      clear_cookies
      post '/poll/create'
      expect_email_not_found_page
    }

    it('fails if post body is nonexistent') {
      post '/poll/create'
      expect(last_response.status).to(be(406))
    }

    it('fails if any fields are empty or missing') {
      @valid_params.each_key { |key|
        params = @valid_params.clone
        params[key] = ''
        post '/poll/create', **params
        expect(last_response.status).to(be(406))
        params.delete(key)
        post '/poll/create', **params
        expect(last_response.status).to(be(406))
      }
    }
  }

  context('get /view') {
    it('shows poll not found') {
      get 'poll/view/does_not_exist'
      expect_not_found_page
    }

    it('shows results of :borda_single polls when finished') {
      poll =  create
      poll.mock_response
      poll.expiration = 1
      poll.save
      get poll.url
      expect_borda_single_finished_page
    }

    it('shows results of :borda_split polls when finished') {
      poll =  create(type: :borda_split)
      poll.mock_response
      poll.expiration = 1
      poll.save
      get poll.url
      expect_borda_split_finished_page
    }

    it('asks for email if responder param is not in poll') {
      poll = create
      get poll.url('not_in_poll')
      expect_email_get_page
    }

    it('stores cookie if responder is in poll') {
      poll = create
      # rubocop:disable Style/StringHashKeys
      get poll.responders.first.url, {}, { 'HTTPS' => 'on' }
      # rubocop:enable Style/StringHashKeys
      expect(last_response.redirect?).to(be(true))
      expect(get_cookie(:email_address)).to(eq('a@a'))
      follow_redirect!
      expect_view_borda_single_page
    }

    it('asks for email if not logged in and no responder param') {
      poll = create
      get poll.url
      expect_email_get_page
    }

    it('asks for email if logged in but not in this poll') {
      set_cookie(:email_address, 'b@b')
      poll = create
      get poll.url
      expect_email_get_page
    }

    it('shows poll if you have not responded to it yet') {
      set_cookie(:email_address, 'a@a')
      poll = create
      get poll.url
      expect_view_borda_single_page
    }

    it('shows expiration time respecting timezone') {
      current_time = 388341770 # 8:43 AM PST
      allow(Time).to(receive(:now).and_return(Time.at(current_time)))

      set_cookie(:email_address, 'a@a')
      poll = create

      rack_mock_session.cookie_jar[:tz] = 'Africa/Djibouti'
      get poll.url
      expect(last_response.body).to(have_content('7:43 PM EAT'))
    }

    it('shows your answers if you have already responded') {
      set_cookie(:email_address, 'a@a')
      poll = create
      poll.mock_response

      get poll.url
      expect_responded_page
    }
  }

  context('post /send') {
    it('sends email successfully') {
      poll =  create
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
      poll = create
      post "/poll/send?poll_id=#{poll.id}"
      expect(last_response.status).to(be(400))

      post "/poll/send?poll_id=#{poll.id}&email=does_not_exist"
      expect_email_not_found_page
    }

    it('rejects sending email for expired poll') {
      ENV['APP_ENV'] = 'development'
      poll = create(expiration: 1)
      post "/poll/send?poll_id=#{poll.id}&email=a@a"
      expect(last_response.status).to(be(405))
    }
  }

  context('post /respond') {
    before(:each) {
      set_cookie(:email_address, 'a@a')
    }

    # rubocop:disable Style/StringHashKeys
    def post_json(data = {})
      post('/poll/respond', data.to_json,
           { 'CONTENT_TYPE' => 'application/json' })
    end
    # rubocop:enable Style/StringHashKeys

    context(':borda_single') {
      it('saves posted results successfully') {
        poll =  create
        post_json({
          poll_id: poll.id,
          responder: poll.responders.first.salt,
          responses: poll.choices.map(&:id)
        })
        expect(last_response.status).to(be(201))

        get "/poll/view/#{poll.id}"
        expect_responded_page

        poll.expiration = 1
        expect(poll.scores.map(&:text)).to(eq(poll.choices.map(&:text)))
        expect(poll.scores.map(&:score)).to(eq([2, 1, 0]))
      }
    }

    context(':borda_split') {
      before(:each) {
        @poll = create(type: :borda_split)
      }

      it('saves posted results successfully') {
        post_json({
          poll_id: @poll.id,
          responder: @poll.responders.first.salt,
          responses: [@poll.choices.first.id],
          bottom_responses: @poll.choices.drop(1).map(&:id)
        })
        expect(last_response.status).to(be(201))

        get "/poll/view/#{@poll.id}"
        expect_responded_page

        @poll.expiration = 1
        expect(@poll.scores.first.text).to(eq(@poll.choices.first.text))
        expect(@poll.scores.map(&:score)).to(eq([2, 0, 0]))
      }

      it('rejects posting with no bottom responses') {
        post_json({
          poll_id: @poll.id,
          responder: @poll.responders.first.salt,
          responses: @poll.choices.map(&:id)
        })
        expect(last_response.status).to(be(400))
      }

      it('rejects posting with invalid bottom responses') {
        post_json({
          poll_id: @poll.id,
          responder: @poll.responders.first.salt,
          responses: @poll.choices.map(&:id),
          bottom_responses: [1, 2]
        })
        expect(last_response.status).to(be(406))
      }
    }

    it('rejects posting to an already responded poll') {
      poll = create
      responder, responses = poll.mock_response

      post_json({
        poll_id: poll.id,
        responder: responder.salt,
        responses: responses
      })
      expect(last_response.status).to(be(409))
    }

    it('rejects an empty post body') {
      post '/poll/respond'
      expect(last_response.status).to(be(400))
    }

    it('rejects posting with empty data object') {
      post_json
      expect(last_response.status).to(be(400))
    }

    it('rejects posting to invalid poll') {
      post_json({ poll_id: 'does_not_exist' })
      expect(last_response.status).to(be(404))
    }

    it('rejects posting with no responder') {
      poll = create
      post_json({ poll_id: poll.id })
      expect(last_response.status).to(be(400))
    }

    it('rejects posting with invalid responder') {
      poll = create
      post_json({ poll_id: poll.id, responder: 'does_not_exist' })
      expect(last_response.status).to(be(404))
    }

    it('rejects posting with no responses') {
      poll = create
      post_json({ poll_id: poll.id, responder: poll.responders.first.salt })
      expect(last_response.status).to(be(400))
    }

    it('rejects posting with invalid responses') {
      poll = create
      post_json({
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: [1, 2]
      })
      expect(last_response.status).to(be(406))
    }

    it('rejects posting with duplicate choices') {
      poll = create
      responses = poll.choices.map(&:id)
      responses[0] = responses[1]
      post_json({
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: responses
      })
      expect(last_response.status).to(be(409))
    }

    it('rejects posting responses to expired poll') {
      poll = create(expiration: 1)
      post_json({
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: poll.choices.map(&:id)
      })
      expect(last_response.status).to(be(405))
    }

    it('rejects posting if you are not logged in') {
      clear_cookies
      poll = create
      post_json({
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: poll.choices.map(&:id)
      })
      expect(last_response.status).to(be(404))
    }

    it('rejects posting if you are logged in as someone else') {
      set_cookie(:email_address, 'someone_else@hey.com')
      poll = create
      post_json({
        poll_id: poll.id,
        responder: poll.responders.first.salt,
        responses: poll.choices.map(&:id)
      })
      expect(last_response.status).to(be(405))
    }
  }
}
