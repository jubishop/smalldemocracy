require_relative '../../lib/models/response'

RSpec.describe(Models::Response) {
  context('::create') {
    it('successfully makes a ranked response') {
      poll = create
      response = poll.responders.first.add_response(
          choice_id: poll.choices.first.id, rank: 0, chosen: true)
      expect(response.responder).to(eq(poll.responders.first))
      expect(response.choice).to(eq(poll.choices.first))
      expect(response.poll).to(eq(poll))
      expect(response.rank).to(eq(0))
      expect(response.chosen).to(be(true))
    }

    it('successfully makes an unranked response') {
      poll = create
      response = poll.responders.first.add_response(
          choice_id: poll.choices.first.id, chosen: true)
      expect(response.rank).to(eq(nil))
    }

    it('calculates results properly when chosen (ranked or unranked)') {
      poll = create
      poll.mock_response
      poll.responses.each { |response|
        expect(response.score).to(eq(poll.choices.length - response.rank))
        response.rank = nil
        expect(response.score).to(eq(0))
        expect(response.point).to(eq(1))
      }
    }

    it('calculates results properly when not chosen') {
      poll = create
      poll.mock_response(chosen: false)
      poll.responses.each { |response|
        expect(response.score).to(eq(0))
        expect(response.point).to(eq(0))
      }
    }

    it('rejects making a response with no responder associated') {
      poll = create
      expect {
        poll.choices.first.add_response(rank: 0,
                                        chosen: true)
      }.to(raise_error(Sequel::HookFailed))
    }

    it('rejects making a response with no choice associated') {
      poll = create
      expect {
        poll.responders.first.add_response(rank: 0,
                                           chosen: true)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects making a response with no chosen') {
      poll = create
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id,
                                           rank: 0)
      }.to(raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two responses with duplicate ranks') {
      poll = create
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
      poll = create
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
      poll = create(expiration: 1)
      expect {
        poll.responders.first.add_response(choice_id: poll.choices.first.id,
                                           rank: 0,
                                           chosen: true)
      }.to(raise_error(Sequel::HookFailed))
    }
  }
}
