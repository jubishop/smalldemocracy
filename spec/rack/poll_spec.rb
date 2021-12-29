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
    let(:valid_params) {
      {
        email: group.creator.email,
        title: 'title',
        question: 'question',
        choices: %w[one two three],
        group_id: group.id,
        expiration: future.form,
        type: type
      }
    }

    shared_examples('create') {
      it('creates a new poll') {
        set_cookie(:email, group.creator.email)
        post '/poll/create', **valid_params
        expect(last_response.redirect?).to(be(true))
        expect_slim(
            'poll/view',
            member: group.creating_member,
            poll: an_instance_of(Models::Poll).and(
                have_attributes(email: group.creator.email,
                                group_id: group.id,
                                type: type)),
            timezone: an_instance_of(TZInfo::DataTimezone))
        follow_redirect!
        expect(last_response.ok?).to(be(true))
      }
    }

    context(':borda_single') {
      let(:type) { :borda_single }
      it_has_behavior('create')
    }

    context(':borda_split') {
      let(:type) { :borda_split }
      it_has_behavior('create')
    }

    context(':choose_one') {
      let(:type) { :choose_one }
      it_has_behavior('create')
    }

    it('rejects any post without a cookie') {
      expect_slim('email/not_found')
      post '/poll/create', **valid_params
    }

    it('fails if post body is nonexistent') {
      set_cookie(:email, group.creator.email)
      post '/poll/create'
      expect(last_response.status).to(be(400))
      puts(last_response.body)
    }

    it('fails if type is invalid') {
      set_cookie(:email, group.creator.email)
      valid_params[:type] = :invalid_type
      post '/poll/create', **valid_params
      expect(last_response.status).to(be(400))
    }

    it('fails if any field is missing or empty') {
      set_cookie(:email, group.creator.email)
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

  # context('get /view') {
  #   def respond_to_poll(poll)
  #     poll.mock_response
  #     poll.expiration = Time.at(1)
  #     poll.save
  #     get(poll.url)
  #   end

  #   it('shows poll not found') {
  #     get 'poll/view/does_not_exist'
  #     expect_not_found_page
  #   }

  #   it('shows results of :borda_single polls when finished') {
  #     respond_to_poll(create)
  #     expect_borda_single_finished_page
  #   }

  #   it('shows results of :borda_split polls when finished') {
  #     respond_to_poll(create(type: :borda_split))
  #     expect_borda_split_finished_page
  #   }

  #   it('shows results of :choose_one polls when finished') {
  #     respond_to_poll(create(type: :choose_one))
  #     expect_choose_one_finished_page
  #   }

  #   it('asks for email if not logged in and no responder param') {
  #     poll = create
  #     get poll.url
  #     expect_email_get_page
  #   }

  #   it('asks for email if logged in but not in this poll') {
  #     set_cookie(:email, 'b@b')
  #     poll = create
  #     get poll.url
  #     expect_email_get_page
  #   }

  #   it('shows poll if you have not responded to it yet') {
  #     set_cookie(:email, 'a@a')
  #     poll = create
  #     get poll.url
  #     expect_view_borda_single_page
  #   }

  #   it('shows expiration time respecting timezone') {
  #     current_time = 388341770 # 11:43 AM EST
  #     allow(Time).to(receive(:now).and_return(Time.at(current_time)))

  #     set_cookie(:email, 'a@a')
  #     poll = create

  #     rack_mock_session.cookie_jar[:tz] = 'Africa/Djibouti'
  #     get poll.url
  #     expect(last_response.body).to(have_content('7:43 PM EAT'))
  #   }

  #   it('shows your answers if you have already responded') {
  #     set_cookie(:email, 'a@a')
  #     poll = create
  #     poll.mock_response

  #     get poll.url
  #     expect_borda_responded_page
  #   }
  # }

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
