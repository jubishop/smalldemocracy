RSpec.describe(Poll, type: :rack_test) {
  context('get /create') {
    it('requests email if you have no cookie') {
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      get '/poll/create'
      expect(last_response.status).to(be(401))
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
      post_json('/poll/create', valid_params)
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
      post_json('/poll/create', valid_params)
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('fails if post body is nonexistent') {
      post '/poll/create'
      expect(last_response.status).to(be(400))
    }

    it('fails if type is invalid') {
      valid_params[:type] = :invalid_type
      post_json('/poll/create', valid_params)
      expect(last_response.status).to(be(400))
    }

    it('fails if any field is missing or empty') {
      valid_params.each_key { |key|
        params = valid_params.clone
        params[key] = ''
        post_json('/poll/create', params)
        expect(last_response.status).to(be(400))
        params.delete(key)
        post_json('/poll/create', params)
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
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      get poll.url
      expect(last_response.status).to(be(401))
    }

    it('shows poll not found if logged in but not in this open poll') {
      poll = create_poll
      set_cookie(:email, 'me@email')
      expect_slim('poll/not_found')
      get poll.url
      expect(last_response.status).to(be(404))
    }

    it('shows poll not found if logged in but not in this finished poll') {
      poll = create_poll(expiration: past)
      set_cookie(:email, 'me@email')
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
      set_cookie(:email, poll.creating_member.email)
      expect_slim(
          'poll/view',
          poll: poll,
          member: poll.creating_member,
          timezone: timezone)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows your answers if you have responded') {
      poll = create_poll
      poll.creating_member.add_response(choice_id: poll.add_choice.id)
      set_cookie(:email, poll.creating_member.email)
      expect_slim(
          'poll/responded',
          poll: poll,
          member: poll.creating_member,
          timezone: timezone)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows results if poll is finished') {
      poll = create_poll
      poll.creating_member.add_response(choice_id: poll.add_choice.id)
      poll.update(expiration: past)
      breakdown, unresponded = poll.breakdown
      set_cookie(:email, poll.creating_member.email)
      expect_slim(
          'poll/finished',
          poll: poll,
          breakdown: breakdown,
          unresponded: unresponded)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /respond') {
    let(:poll) { create_poll }
    let(:choice) { poll.add_choice }
    let(:member) { poll.creating_member }

    before(:each) {
      set_cookie(:email, poll.email)
    }

    it('rejects an empty post body') {
      post_json('/poll/respond')
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(eq('No poll found'))
    }

    it('rejects posting to invalid poll') {
      post_json('/poll/respond', { hash_id: 'does_not_exist' })
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(eq('No poll found'))
    }

    it('rejects posting if you are not logged in') {
      clear_cookies
      post_json('/poll/respond', { hash_id: poll.hashid })
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('rejects posting if you are not a member of the poll') {
      set_cookie(:email, 'me@email')
      post_json('/poll/respond', { hash_id: poll.hashid })
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(eq('Poll not found'))
    }

    it('rejects posting responses to expired poll') {
      poll.update(expiration: past)
      post_json('/poll/respond', { hash_id: poll.hashid })
      expect(last_response.status).to(be(405))
      expect(last_response.body).to(eq('Poll has already finished'))
    }

    context(':choose_one') {
      let(:poll) { create_poll(type: :choose_one) }

      it('saves choice successfully') {
        expect(member.responses).to(be_empty)
        post_json('/poll/respond',
                  { hash_id: poll.hashid, choice_id: choice.id })
        expect(last_response.status).to(be(201))
        expect(last_response.body).to(eq('Poll response added'))
        expect(member.response(poll_id: poll.id).choice).to(eq(choice))

        expect_slim(
            'poll/responded',
            poll: poll,
            member: member,
            timezone: an_instance_of(TZInfo::DataTimezone))
        get poll.url
      }

      it('rejects posting to an already responded poll') {
        choice = poll.add_choice
        member.add_response(choice_id: choice.id)
        another_choice = poll.add_choice

        post_json('/poll/respond',
                  { hash_id: poll.hashid, choice_id: another_choice.id })
        expect(last_response.status).to(be(409))
        expect(last_response.body).to(match(/Member has already responded/))
      }

      it('rejects posting with no choice_id') {
        post_json('/poll/respond', { hash_id: poll.hashid })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(eq('No choice_id given'))
      }

      it('rejects posting with invalid choice id') {
        post_json('/poll/respond',
                  { hash_id: poll.hashid, choice_id: 'invalid' })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(match(/PG::InvalidTextRepresentation/))
      }

      it('rejects posting with non existent choice id') {
        post_json('/poll/respond',
                  { hash_id: poll.hashid, choice_id: 987654321 })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(eq('Response has no poll'))
      }
    }

    context(':borda') {
      let(:poll) { create_poll(type: :borda_single) }
      let(:choices) { Array.new(10).fill { poll.add_choice } }
      let(:responses) { choices.shuffle.map(&:id) }

      it('rejects posting to an already responded poll') {
        choice = poll.add_choice
        member.add_response(choice_id: choice.id)

        post_json('/poll/respond',
                  { hash_id: poll.hashid, responses: [choice.id] })
        expect(last_response.status).to(be(409))
        expect(last_response.body).to(match(/Member has already responded/))
      }

      it('rejects posting with no responses') {
        post_json('/poll/respond', { hash_id: poll.hashid })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(eq('No responses given'))
      }

      it('rejects posting with invalid responses') {
        post_json(
            '/poll/respond',
            {
              hash_id: poll.hashid,
              responses: responses.fill { rand(10000) }
            })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(eq('Response has no poll'))
      }

      it('rejects posting with duplicate choices') {
        responses[0] = responses[1]
        post_json('/poll/respond',
                  { hash_id: poll.hashid, responses: responses })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(
            match(/violates unique constraint "response_unique"/))
      }

      context(':borda_single') {
        let(:poll) { create_poll(type: :borda_single) }

        it('saves rankings successfully') {
          expect(member.responses).to(be_empty)
          post_json('/poll/respond',
                    { hash_id: poll.hashid, responses: responses })
          expect(last_response.status).to(be(201))
          expect(last_response.body).to(eq('Poll response added'))
          poll_responses = member.responses(poll_id: poll.id)
          expect((poll_responses).map(&:choice_id)).to(match_array(responses))
          responses.each_with_index { |choice_id, rank|
            poll_response = poll_responses.find { |response|
              response.choice_id == choice_id
            }
            expect(poll_response.score).to(eq(poll.choices.length - rank - 1))
          }

          expect_slim(
              'poll/responded',
              poll: poll,
              member: member,
              timezone: an_instance_of(TZInfo::DataTimezone))
          get poll.url
        }

        it('rejects posting with incorrect number of responses') {
          post_json('/poll/respond',
                    { hash_id: poll.hashid, responses: responses.drop(1) })
          expect(last_response.status).to(be(400))
          expect(last_response.body).to(
              eq('Response set does not match number of choices'))
        }
      }

      context(':borda_split') {
        let(:poll) { create_poll(type: :borda_split) }
        let(:responses) { choices.shuffle.map(&:id).drop(4) }

        it('saves rankings successfully') {
          expect(member.responses).to(be_empty)
          post_json(
              '/poll/respond',
              {
                hash_id: poll.hashid,
                responses: responses
              })
          expect(last_response.status).to(be(201))
          expect(last_response.body).to(eq('Poll response added'))
          poll_responses = member.responses(poll_id: poll.id)
          expect((poll_responses).map(&:choice_id)).to(match_array(responses))
          responses.each_with_index { |choice_id, rank|
            poll_response = poll_responses.find { |response|
              response.choice_id == choice_id
            }
            expect(poll_response.score).to(eq(poll.choices.length - rank))
          }

          expect_slim(
              'poll/responded',
              poll: poll,
              member: member,
              timezone: an_instance_of(TZInfo::DataTimezone))
          get poll.url
        }
      }
    }
  }
}
