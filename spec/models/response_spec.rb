require_relative '../../lib/models/response'

# TODO: Go over this entirely
RSpec.describe(Models::Response) {
  context('::create') {
    it('successfully makes a response') {
      poll = create
      response = poll.responders.first.add_response(
          choice_id: poll.choices.first.id, score: 1)
      expect(response.responder).to(eq(poll.responders.first))
      expect(response.choice).to(eq(poll.choices.first))
      expect(response.poll).to(eq(poll))
      expect(response.score).to(eq(1))
    }

    it('rejects making a response with no responder associated') {
      poll = create
      expect {
        poll.choices.first.add_response({})
      }.to(raise_error(ArgumentError))
    }

    it('rejects making a response with no choice associated') {
      poll = create
      expect {
        poll.responders.first.add_response({})
      }.to(raise_error(ArgumentError))
    }

    it('rejects creating two responses with duplicate choices') {
      poll = create
      poll.responders.first.add_response(choice_id: poll.choices[0].id)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices[0].id)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a response on finished poll') {
      poll = create(expiration: 1)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id)
      }.to(raise_error(Sequel::HookFailed))
    }
  }
}
