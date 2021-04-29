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
      expect {
        poll.choices.first.add_response(rank: 0,
                                        chosen: true)
      }.to(raise_error(Sequel::HookFailed))
    }

    it('rejects making a response with no choice associated') {
      poll = create_poll
      expect {
        poll.responders.first.add_response(rank: 0,
                                           chosen: true)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects making a response with no rank') {
      poll = create_poll
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id,
                                           chosen: true)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects making a response with no chosen') {
      poll = create_poll
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id,
                                           rank: 0)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responses with duplicate ranks') {
      poll = create_poll
      poll.responders.first.add_response(choice_id: poll.choices[0].id,
                                         rank: 1,
                                         chosen: true)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices[1].id,
                                           rank: 1,
                                           chosen: true)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responses with duplicate choices') {
      poll = create_poll
      poll.responders.first.add_response(choice_id: poll.choices[0].id,
                                         rank: 1,
                                         chosen: true)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices[0].id,
                                           rank: 2,
                                           chosen: true)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a response on finished poll') {
      poll = create_poll(expiration: 1)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id,
                                           rank: 0,
                                           chosen: true)
      }.to(raise_error(Sequel::HookFailed))
    }
  }
}
