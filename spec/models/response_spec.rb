require_relative '../../lib/models/response'

RSpec.describe(Models::Response) {
  context('::create') {
    it('successfully makes a basic response') {
      poll = create_poll
      response = poll.responders.first.add_response(
          choice_id: poll.choices.first.id, rank: 0, chosen: true)
      expect(response.responder).to(eq(poll.responders.first))
      expect(response.choice).to(eq(poll.choices.first))
      expect(response.rank).to(eq(0))
      expect(response.chosen).to(be(true))
    }

    it('rejects making a response with no responder associated') {
      poll = create_poll
      expect { Models::Response.create(choice_id: poll.choices.first.id) }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects making a response with no choice associated') {
      poll = create_poll
      expect {
        Models::Response.create(
            responder_id: poll.responders.first.id)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects making a response with no rank') {
      poll = create_poll
      expect {
        poll.responders.first.add_response(
            choice_id: poll.choices.first.id)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responses with duplicate ranks') {
      poll = create_poll
      poll.responders.first.add_response(choice_id: poll.choices[0].id, rank: 1)
      expect {
        poll.responders.first.add_response(
            choice_id: poll.choices[1].id, rank: 1)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responses with duplicate choices') {
      poll = create_poll
      poll.responders.first.add_response(choice_id: poll.choices[0].id, rank: 1)
      expect {
        poll.responders.first.add_response(
            choice_id: poll.choices[0].id, rank: 2)
      }.to(raise_error(Sequel::ConstraintViolation))
    }
  }
}
