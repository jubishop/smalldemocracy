require_relative '../../lib/models/responder'

RSpec.describe(Models::Responder) {
  context('::create') {
    it('successfully makes a basic responder') {
      poll = create
      responder = poll.add_responder(email: 'yo@yo')
      expect(responder.email).to(eq('yo@yo'))
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

  context('#response') {
    before(:each) {
      @poll = create
      @responder = @poll.add_responder(email: 'yo@yo')
    }

    it('returns only response if only one') {
      response = @responder.add_response(choice_id: @poll.choices.first.id)
      expect(@responder.response).to(eq(response))
    }

    it('raises error if more than one response exists') {
      @responder.add_response(choice_id: @poll.choices.first.id)
      @responder.add_response(choice_id: @poll.choices.last.id)
      expect { @responder.response }.to(raise_error(Models::RangeError))
    }
  }
}
