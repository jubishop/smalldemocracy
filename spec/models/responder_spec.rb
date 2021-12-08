require_relative '../../lib/models/responder'

RSpec.describe(Models::Responder) {
  context('::create') {
    it('successfully makes a basic responder') {
      poll = create
      responder = poll.add_responder(email: 'yo@yo')
      expect(responder.email).to(eq('yo@yo'))
      expect(responder.salt.length).to(be >= 8)
    }

    it('rejects making a responder with no poll associated') {
      expect { Models::Responder.create(email: 'a@a') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responders with the same email') {
      poll = create
      poll.add_responder(email: 'yo@yo')
      expect { poll.add_responder(email: 'yo@yo') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a responder with empty email') {
      poll = create
      expect { poll.add_responder(email: '') }.to(
          raise_error(Sequel::HookFailed, 'Email: , is invalid'))
    }

    it('rejects creating a responder with invalid email') {
      poll = create
      expect { poll.add_responder(email: 'not_an_email') }.to(
          raise_error(Sequel::HookFailed, 'Email: not_an_email, is invalid'))
    }
  }

  context('#url') {
    it('creates valid responder url') {
      poll = create
      responder = poll.add_responder(email: 'yo@yo')
      expect(responder.url).to(
          eq("/poll/view/#{poll.id}?responder=#{responder.salt}"))
    }
  }

  context('#response') {
    before(:each) {
      @poll = create
      @responder = @poll.add_responder(email: 'yo@yo')
    }

    it('returns only response if only one') {
      response = @responder.add_response(choice_id: @poll.choices.first.id,
                                         chosen: true)
      expect(@responder.response).to(eq(response))
    }

    it('raises error if only response is not chosen') {
      @responder.add_response(choice_id: @poll.choices.first.id, chosen: false)
      expect { @responder.response }.to(raise_error(Models::RangeError))
    }

    it('raises error if more than one response exists') {
      @responder.add_response(choice_id: @poll.choices.first.id, chosen: true)
      @responder.add_response(choice_id: @poll.choices.last.id, chosen: true)
      expect { @responder.response }.to(raise_error(Models::RangeError))
    }
  }
}
