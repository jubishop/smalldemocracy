require 'duration'
require 'tzinfo'

require_relative 'shared_examples/entity_guards'

RSpec.describe(Poll, type: :rack_test) {
  let(:group) { create_group }
  let(:poll) { group.add_poll }
  let(:type) { :choose_one }
  let(:expiration) { future }
  let(:choices) { %w[one two three] }
  let(:member) { group.creating_member }
  let(:email) { group.email }
  let(:valid_params) {
    {
      title: 'title',
      question: 'question',
      choices: choices,
      group_id: group.id,
      expiration: expiration.form,
      type: type
    }
  }

  let(:entity) { create_poll(email: email) }
  it_has_behavior('entity guards', 'poll')

  context('get /create') {
    let(:user) { create_user }
    let(:email) { user.email }
    let(:group) { user.add_group }

    it('shows creation page') {
      expect_slim('poll/create', user: user,
                                 form_time: an_instance_of(Time),
                                 group_id: 0)
      get 'poll/create'
      expect(last_response.ok?).to(be(true))
    }

    it('shows creation page and propagates :group_id parameter') {
      expect_slim('poll/create', user: user,
                                 form_time: an_instance_of(Time),
                                 group_id: group.id)
      get 'poll/create', group_id: group.id
      expect(last_response.ok?).to(be(true))
    }
  }

  context('post /create') {
    it('creates a new poll with choices and redirects to view') {
      post '/poll/create', valid_params
      expect(last_response.redirect?).to(be(true))
      poll = group.polls.first
      expect(poll).to(have_attributes(email: email,
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

    it('fails if type is invalid') {
      valid_params[:type] = :invalid_type
      post '/poll/create', valid_params
      expect(last_response.status).to(be(400))
    }

    it('fails if poll expiration is invalid string') {
      valid_params[:expiration] = 'Sometime tomorrow'
      post '/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('Sometime tomorrow is invalid date'))
    }

    it('fails if poll expiration is in the past') {
      valid_params[:expiration] = past.form
      post '/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to time in the past'))
    }

    it('fails if poll expiration is more than 90 days out') {
      valid_params[:expiration] = (Time.now + 91.days).form
      post '/poll/create', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to more than 90 days in the future'))
    }

    it('fails if user is not part of poll group') {
      email = create_user.email
      set_cookie(:email, email)
      post '/poll/create', valid_params
      expect(last_response.body).to(
          eq("Creator #{email} is not a member of #{group.name}"))
      expect(last_response.status).to(be(400))
    }
  }

  context('get /view') {
    let(:tz_name) { 'Africa/Djibouti' }
    let(:timezone) { TZInfo::Timezone.get(tz_name) }
    let(:member) { poll.creating_member }
    let(:email) { member.email }

    before(:each) { rack_mock_session.cookie_jar['tz'] = tz_name }

    it('shows poll if you have not responded') {
      expect_slim('poll/view', poll: poll, member: member, timezone: timezone)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows your answers if you have responded') {
      member.add_response(choice_id: poll.add_choice.id)
      expect_slim('poll/responded',
                  poll: poll,
                  member: member,
                  timezone: timezone)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }

    it('shows results if poll is finished') {
      member.add_response(choice_id: poll.add_choice.id)
      freeze_time(future + 1.day)
      breakdown, unresponded = poll.breakdown
      expect_slim('poll/finished',
                  poll: poll,
                  member: member,
                  breakdown: breakdown,
                  unresponded: unresponded)
      get poll.url
      expect(last_response.ok?).to(be(true))
    }
  }

  context('get /edit') {
    it('shows edit page') {
      set_cookie(:email, poll.email)
      expect_slim('poll/edit', poll: poll)
      get poll.edit_url
      expect(last_response.ok?).to(be(true))
    }

    it('redirects and asks for email with no cookie') {
      clear_cookies
      get poll.edit_url
      expect(last_response.redirect?).to(be(true))
      expect_slim(:get_email, req: an_instance_of(Tony::Request))
      follow_redirect!
      expect(last_response.status).to(eq(401))
    }

    it('returns not found if user is not in poll') {
      set_cookie(:email, random_email)
      get poll.edit_url
      expect(last_response.redirect?).to(be(true))
      expect_slim('poll/not_found')
      follow_redirect!
      expect(last_response.status).to(eq(404))
    }

    it('redirects to viewing poll if user is not poll creator') {
      member = poll.group.add_member
      set_cookie(:email, member.email)
      get poll.edit_url
      expect(last_response.redirect?).to(be(true))
      expect_slim('poll/view',
                  poll: poll,
                  member: member,
                  timezone: an_instance_of(TZInfo::DataTimezone))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }

    it('redirects to viewing poll if there are responses by others') {
      set_cookie(:email, poll.email)
      member = group.add_member
      choice = poll.add_choice
      member.add_response(choice_id: choice.id)
      get poll.edit_url
      expect(last_response.redirect?).to(be(true))
      expect_slim('poll/view',
                  poll: poll,
                  member: poll.creating_member,
                  timezone: an_instance_of(TZInfo::DataTimezone))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }

    it('redirects to viewing responded poll if session user has responded') {
      set_cookie(:email, poll.email)
      choice = poll.add_choice
      choice.add_response(member_id: poll.creating_member.id)
      get poll.edit_url
      expect(last_response.redirect?).to(be(true))
      expect_slim('poll/responded',
                  poll: poll,
                  member: poll.creating_member,
                  timezone: an_instance_of(TZInfo::DataTimezone))
      follow_redirect!
      expect(last_response.ok?).to(be(true))
    }
  }

  shared_examples('poll mutability') { |operation|
    it('fails with no cookie') {
      clear_cookies
      post "poll/#{operation}", valid_params
      expect(last_response.status).to(be(401))
      expect(last_response.body).to(eq('No email found'))
    }

    it('fails if any field is missing or empty') {
      valid_params.each_key { |key|
        params = valid_params.clone
        params[key] = ''
        post "/poll/#{operation}", params
        expect(last_response.status).to(be(400))
        params.delete(key)
        post "/poll/#{operation}", params
        expect(last_response.status).to(be(400))
      }
    }

    it('fails if user is not poll creator') {
      email = poll.group.add_member.email
      set_cookie(:email, email)
      post "poll/#{operation}", valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("#{email} is not the creator of #{poll.title}"))
    }
  }

  shared_examples('poll content mutability') { |operation|
    it_has_behavior('poll mutability', operation)

    it('fails if poll has any responses') {
      choice = poll.add_choice
      choice.add_response
      post "poll/#{operation}", valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq("#{poll.title} already has responses"))
    }
  }

  context('post /title') {
    let(:email) { poll.email }
    let(:poll_title) { 'A title' }
    let(:valid_params) {
      {
        hash_id: poll.hashid,
        title: poll_title
      }
    }

    it_has_behavior('poll content mutability', 'title')

    it('edits title of poll') {
      expect(poll.title).to_not(eq(poll_title))
      post 'poll/title', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Poll title changed'))
      expect(poll.reload.title).to(eq(poll_title))
    }
  }

  context('post /question') {
    let(:email) { poll.email }
    let(:poll_question) { 'A question' }
    let(:valid_params) {
      {
        hash_id: poll.hashid,
        question: poll_question
      }
    }

    it_has_behavior('poll content mutability', 'question')

    it('edits question of poll') {
      expect(poll.question).to_not(eq(poll_question))
      post 'poll/question', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Poll question changed'))
      expect(poll.reload.question).to(eq(poll_question))
    }
  }

  shared_context('poll choice mutability') {
    let(:email) { poll.email }
    let(:choice_text) { 'A choice' }
    let(:valid_params) {
      {
        hash_id: poll.hashid,
        choice: choice_text
      }
    }
  }

  context('post /add_choice') {
    include_context('poll choice mutability')
    it_has_behavior('poll content mutability', 'add_choice')

    it('adds choice to poll') {
      expect(poll.choices).to(be_empty)
      post 'poll/add_choice', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Poll choice added'))
      expect(poll.choices(reload: true).map(&:text)).to(eq([choice_text]))
    }

    it('rejects adding choice that is already in the poll') {
      poll.add_choice(text: choice_text)
      post 'poll/add_choice', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          match(/violates unique constraint "choice_unique"/))
    }
  }

  context('post /remove_choice') {
    include_context('poll choice mutability')

    before(:each) {
      poll.add_choice(text: choice_text)
    }

    it_has_behavior('poll content mutability', 'remove_choice')

    it('removes choice from poll') {
      expect(poll.choices.map(&:text)).to(eq([choice_text]))
      post 'poll/remove_choice', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Poll choice removed'))
      expect(poll.choices(reload: true)).to(be_empty)
    }

    it('rejects removing choice that is not in the poll') {
      valid_params[:choice] = 'Not in poll'
      post 'poll/remove_choice', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq("Not in poll is not a choice of #{poll.title}"))
    }
  }

  context('post /expiration') {
    let(:email) { poll.email }
    let(:poll_expiration) { future + 10.days }
    let(:valid_params) {
      {
        hash_id: poll.hashid,
        expiration: poll_expiration.form
      }
    }

    include_context('poll mutability', 'expiration')

    it('updates poll expiration') {
      expect(poll.expiration).to_not(eq(poll_expiration))
      post 'poll/expiration', valid_params
      expect(last_response.status).to(be(201))
      expect(last_response.body).to(eq('Poll expiration updated'))
      expect(poll.reload.expiration).to(eq(poll_expiration))
    }

    it('fails if new expiration is in the past') {
      valid_params[:expiration] = past.form
      post 'poll/expiration', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to time in the past'))
      expect(poll.expiration).to_not(eq(valid_params[:expiration]))
    }

    it('fails if new expiration is more than 90 days out') {
      valid_params[:expiration] = (Time.now + 91.days).form
      post 'poll/expiration', valid_params
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(
          eq('Poll expiration set to more than 90 days in the future'))
      expect(poll.expiration).to_not(eq(valid_params[:expiration]))
    }
  }

  context('post /respond') {
    let(:email) { poll.email }
    let(:choice) { poll.add_choice }
    let(:member) { poll.creating_member }

    it('rejects an empty post body') {
      post_json('/poll/respond')
      expect(last_response.status).to(be(400))
      expect(last_response.body).to(eq('No hash_id given'))
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
      set_cookie(:email, random_email)
      post_json('/poll/respond', { hash_id: poll.hashid })
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(eq('Poll not found'))
    }

    it('rejects posting responses to expired poll') {
      freeze_time(future + 1.day)
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
        expect(member.responses(poll_id: poll.id).first.choice).to(eq(choice))

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
        expect(last_response.body).to(
            eq("Member has already responded to #{poll.title}"))
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
      let(:poll) { create_poll(type: type) }
      let(:type) { :borda_single }
      let(:choices) { Array.new(10).fill { poll.add_choice } }
      let(:responses) { choices.shuffle.map(&:id) }

      it('rejects posting to an already responded poll') {
        choice = poll.add_choice
        member.add_response(choice_id: choice.id)

        post_json('/poll/respond',
                  { hash_id: poll.hashid, responses: [choice.id] })
        expect(last_response.status).to(be(409))
        expect(last_response.body).to(
            eq("Member has already responded to #{poll.title}"))
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
              responses: responses.fill { rand(1000000000000) }
            })
        expect(last_response.status).to(be(400))
        expect(last_response.body).to(eq('Response has no poll'))
      }

      shared_examples('saves rankings') {
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
            expect(poll_response.data[:score]).to(
                eq(score_calculation.call(rank)))
          }

          expect_slim(
              'poll/responded',
              poll: poll,
              member: member,
              timezone: an_instance_of(TZInfo::DataTimezone))
          get poll.url
        }
      }

      context(':borda_single') {
        let(:score_calculation) {
          ->(rank) { poll.choices.length - rank - 1 }
        }

        it_has_behavior('saves rankings')

        it('rejects posting with incorrect number of responses') {
          post_json('/poll/respond',
                    { hash_id: poll.hashid, responses: responses.drop(1) })
          expect(last_response.status).to(be(400))
          expect(last_response.body).to(
              eq('Response set does not match number of choices'))
        }
      }

      context(':borda_split') {
        let(:type) { :borda_split }
        let(:responses) { choices.shuffle.map(&:id).drop(4) }
        let(:score_calculation) {
          ->(rank) { poll.choices.length - rank }
        }

        it_has_behavior('saves rankings')
      }
    }
  }
}
