require_relative '../../lib/models/response'

RSpec.describe(Models::Response, type: :model) {
  context('.create') {
    it('creates a response with no score') {
      response = create_response
      expect(response.score).to(be(nil))
    }

    it('creates a response with a score') {
      response = create_response(score: 10)
      expect(response.score).to(be(10))
    }
  }

  context('#destroy') {
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

  context('#choice') {
    it('finds its choice') {
      choice = create_choice
      response = choice.add_response(member_id: choice.poll.creating_member.id)
      expect(response.choice).to(eq(choice))
    }
  }

  context('#member') {
    it('finds its member') {
      poll = create_poll
      response = poll.creating_member.add_response(
          choice_id: poll.add_choice.id)
      expect(response.member).to(eq(poll.creating_member))
    }
  }

  context('#poll') {
    it('finds its poll through join table') {
      poll = create_poll
      response = poll.creating_member.add_response(
          choice_id: poll.add_choice.id)
      expect(response.poll).to(eq(poll))
    }
  }
}
