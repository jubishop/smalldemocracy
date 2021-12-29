RSpec.describe(Poll, type: :rack_test) {
  context('get /create') {
    it('requests email if you have no cookie') {
      expect_slim('email/get', req: an_instance_of(Tony::Request))
      get '/poll/create'
      expect(last_response.ok?).to(be(true))
    }

    it('shows poll creation form if you have an email cookie') {
      set_cookie(:email, 'test@example.com')
      expect_slim('poll/create')
      get '/poll/create'
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    let(:group) { create_group }
    let(:type) { :choose_one }
    let(:expiration) { future }
    let(:choices) { %w[one two three] }
    let(:member) { group.creating_member }
    let(:valid_params) {
      {
        email: member.email,
        title: 'title',
        question: 'question',
        choices: choices,
        group_id: group.id,
        expiration: expiration.form,
        type: type
      }
    }
    let(:poll) { group.polls.first }
    before(:each) { set_cookie(:email, member.email) }

    it('creates a new poll with choices and redirects to view') {
      post '/poll/create', **valid_params
      expect(last_response.redirect?).to(be(true))
      expect(poll).to(have_attributes(email: member.email,
                                      title: 'title',
                                      question: 'question',
                                      group_id: group.id,
                                      expiration: expiration,
                                      type: type))
      expect(poll.choices.map(&:text)).to(match_array(choices))
      expect_slim(
          'poll/view',
          poll: poll,
          member: member,
          timezone: an_instance_of(TZInfo::DataTimezone))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }

    it('rejects any post without a cookie') {
      clear_cookies
      expect_slim('email/not_found')
      post '/poll/create', **valid_params
    }

    it('fails if post body is nonexistent') {
      post '/poll/create'
      expect(last_response.status).to(be(400))
    }

    it('fails if type is invalid') {
      valid_params[:type] = :invalid_type
      post '/poll/create', **valid_params
      expect(last_response.status).to(be(400))
    }

    it('fails if any field is missing or empty') {
      valid_params.each_key { |key|
        params = valid_params.clone
        params[key] = ''
        post '/poll/create', **params
        expect(last_response.status).to(be(400))
        params.delete(key)
        post '/poll/create', **params
        expect(last_response.status).to(be(400))
      }
    }
  }

  context('get /view') {
    let(:tz_name) { 'Africa/Djibouti' }
    let(:timezone) { TZInfo::Timezone.get(tz_name) }

    before(:each) {
      rack_mock_session.cookie_jar['tz'] = tz_name
    }

    it('asks for email if not logged in') {
      poll = create_poll
      expect_slim('email/get', req: an_instance_of(Tony::Request))
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows poll not found if logged in but not in this poll') {
      set_cookie(:email, 'me@email')
      poll = create_poll
      expect_slim('poll/not_found')
      get poll.url
      expect(last_response.status).to(be(404))
    }

    it('shows poll not found if logged in but not in this finished poll') {
      set_cookie(:email, 'me@email')
      poll = create_poll(expiration: past)
      expect_slim('poll/not_found')
      get poll.url
      expect(last_response.status).to(be(404))
    }

    it('shows poll not found for invalid urls') {
      set_cookie(:email, 'me@email')
      expect_slim('poll/not_found')
      get 'poll/view/does_not_exist'
      expect(last_response.status).to(be(404))
    }

    it('shows poll if you have not responded') {
      poll = create_poll
      expect_slim(
          'poll/view',
          poll: poll,
          member: poll.creating_member,
          timezone: timezone)
      set_cookie(:email, poll.creating_member.email)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows your answers if you have responded') {
      poll = create_poll
      poll.creating_member.add_response(choice_id: poll.add_choice.id)
      expect_slim(
          'poll/responded',
          poll: poll,
          member: poll.creating_member,
          timezone: timezone)
      set_cookie(:email, poll.creating_member.email)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows results of poll when finished') {
      poll = create_poll
      poll.creating_member.add_response(choice_id: poll.add_choice.id)
      poll.update(expiration: past)
      breakdown, unresponded = poll.breakdown
      expect_slim(
          'poll/finished',
          poll: poll,
          breakdown: breakdown,
          unresponded: unresponded)
      set_cookie(:email, poll.creating_member.email)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }
  }

  # context('post /respond') {
  #   before(:each) {
  #     set_cookie(:email, 'a@a')
  #   }

  #   # rubocop:disable Style/StringHashKeys
  #   def post_json(data = {})
  #     post('/poll/respond', data.to_json,
  #          { 'CONTENT_TYPE' => 'application/json' })
  #   end
  #   # rubocop:enable Style/StringHashKeys

  #   context(':choose_one') {
  #     before(:each) {
  #       @poll = create(type: :choose_one)
  #     }

  #     it('saves posted results successfully') {
  #       post_json({ poll_id: @poll.id, choice: @poll.choices.first.id })
  #       expect(last_response.status).to(be(201))

  #       get "/poll/view/#{@poll.id}"
  #       expect_choose_responded_page
  #     }

  #     it('rejects posting with an incorrect choice id') {
  #       post_json({ poll_id: 'bad_id', choice: @poll.choices.first.id })
  #       expect(last_response.status).to(be(404))
  #     }

  #     it('rejects posting with no choice id') {
  #       post_json({ choice: @poll.choices.first.id })
  #       expect(last_response.status).to(be(400))
  #     }
  #   }

  #   context(':borda_single') {
  #     it('saves posted results successfully') {
  #       poll = create
  #       post_json({ poll_id: poll.id, responses: poll.choices.map(&:id) })
  #       expect(last_response.status).to(be(201))

  #       get "/poll/view/#{poll.id}"
  #       expect_borda_responded_page

  #       poll.expiration = 1
  #       expect(poll.scores.map(&:text)).to(eq(poll.choices.map(&:text)))
  #       expect(poll.scores.map(&:score)).to(eq([2, 1, 0]))
  #     }
  #   }

  #   context(':borda_split') {
  #     before(:each) {
  #       @poll = create(type: :borda_split)
  #     }

  #     it('saves posted results successfully') {
  #       post_json({
  #         poll_id: @poll.id,
  #         responses: [@poll.choices.first.id],
  #         bottom_responses: @poll.choices.drop(1).map(&:id)
  #       })
  #       expect(last_response.status).to(be(201))

  #       get "/poll/view/#{@poll.id}"
  #       expect_borda_responded_page

  #       @poll.expiration = 1
  #       expect(@poll.scores.length).to(be(1))
  #       expect(@poll.scores.first.text).to(eq('one'))
  #       expect(@poll.scores.first.score).to(be(3))
  #     }

  #     it('rejects posting with no bottom responses') {
  #       post_json({ poll_id: @poll.id, responses: @poll.choices.map(&:id) })
  #       expect(last_response.status).to(be(400))
  #     }

  #     it('rejects posting with invalid bottom responses') {
  #       post_json({
  #         poll_id: @poll.id,
  #         responses: @poll.choices.map(&:id),
  #         bottom_responses: [1, 2]
  #       })
  #       expect(last_response.status).to(be(406))
  #     }
  #   }

  #   it('rejects posting to an already responded poll') {
  #     poll = create
  #     responses = poll.mock_response

  #     post_json({ poll_id: poll.id, responses: responses })
  #     expect(last_response.status).to(be(409))
  #   }

  #   it('rejects an empty post body') {
  #     post '/poll/respond'
  #     expect(last_response.status).to(be(400))
  #   }

  #   it('rejects posting with empty data object') {
  #     post_json
  #     expect(last_response.status).to(be(400))
  #   }

  #   it('rejects posting to invalid poll') {
  #     post_json({ poll_id: 'does_not_exist' })
  #     expect(last_response.status).to(be(404))
  #   }

  #   it('rejects posting with no responder') {
  #     poll = create
  #     post_json({ poll_id: poll.id })
  #     expect(last_response.status).to(be(400))
  #   }

  #   it('rejects posting with no responses') {
  #     poll = create
  #     post_json({ poll_id: poll.id })
  #     expect(last_response.status).to(be(400))
  #   }

  #   it('rejects posting with invalid responses') {
  #     poll = create
  #     post_json({ poll_id: poll.id, responses: [1, 2] })
  #     expect(last_response.status).to(be(406))
  #   }

  #   it('rejects posting with duplicate choices') {
  #     poll = create
  #     responses = poll.choices.map(&:id)
  #     responses[0] = responses[1]
  #     post_json({ poll_id: poll.id, responses: responses })
  #     expect(last_response.status).to(be(409))
  #   }

  #   it('rejects posting responses to expired poll') {
  #     poll = create(expiration: 1)
  #     post_json({ poll_id: poll.id, responses: poll.choices.map(&:id) })
  #     expect(last_response.status).to(be(405))
  #     expect(last_response.body).to(eq('Poll has already finished'))
  #   }

  #   it('rejects posting if you are not logged in') {
  #     clear_cookies
  #     poll = create
  #     post_json({ poll_id: poll.id, responses: poll.choices.map(&:id) })
  #     expect(last_response.status).to(be(404))
  #   }

  #   it('rejects posting if you are logged in as someone else') {
  #     set_cookie(:email, 'someone_else@hey.com')
  #     poll = create
  #     post_json({ poll_id: poll.id, responses: poll.choices.map(&:id) })
  #     expect(last_response.status).to(be(405))
  #     expect(last_response.body).to(
  #         eq('someone_else@hey.com is not a responder to this poll'))
  #   }
  # }
}
