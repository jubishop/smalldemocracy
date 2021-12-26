require_relative '../../lib/models/response'

# TODO: Go over this entirely
# TODO: Test can't remove response after poll expired.

RSpec.describe(Models::Response) {
  context('create') {
    it('creates a response with no score') {
      response = create_response
      expect(response.score).to(be(nil))
    }

    it('creates a response with a score') {
      response = create_response(score: 10)
      expect(response.score).to(be(10))
    }
  }

  context('destroy') {
    it('destroys itself from choice') {
      response = create_response
      choice = response.choice
      expect(choice.responses).to_not(be_empty)
      expect(response.exists?).to(be(true))
      choice.remove_response(response)
      expect(choice.responses).to(be_empty)
      expect(response.exists?).to(be(false))
    }

    it('destroys itself from member') {
      response = create_response
      member = response.member
      expect(member.responses).to_not(be_empty)
      expect(response.exists?).to(be(true))
      member.remove_response(response)
      expect(member.responses).to(be_empty)
      expect(response.exists?).to(be(false))
    }

    it('rejects destroying from an expired poll') {
      response = create_response
      response.poll.update(expiration: past)
      expect { response.destroy }.to(
          raise_error(Sequel::HookFailed,
                      'Response removed from expired poll'))
    }
  }
}
