require_relative '../../lib/models/responder'

RSpec.describe(Models::Responder) {
  context('::create') {
    it('successfully makes a basic responder') {
      poll = create_borda
      responder = poll.add_responder(email: 'yo@yo')
      expect(responder.email).to(eq('yo@yo'))
      expect(responder.salt.length).to(be >= 8)
    }

    it('rejects making a responder with no poll associated') {
      expect { Models::Responder.create(email: 'a@a') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responders with the same email') {
      poll = create_borda
      poll.add_responder(email: 'yo@yo')
      expect { poll.add_responder(email: 'yo@yo') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a responder with empty email') {
      poll = create_borda
      expect { poll.add_responder(email: '') }.to(
          raise_error(Sequel::HookFailed))
    }

    it('rejects creating a responder with invalid email') {
      poll = create_borda
      expect { poll.add_responder(email: 'not_a_real_email') }.to(
          raise_error(Sequel::HookFailed))
    }
  }
}
