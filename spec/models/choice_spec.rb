require_relative '../../lib/models/choice'

RSpec.describe(Models::Choice) {
  context('create') {
    it('creates a choice') {
      choice = create_choice(text: 'text')
      expect(choice.text).to(eq('text'))
    }

    it('rejects creating a choice with no text') {
      expect { create_choice(text: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "text"/))
    }

    it('rejects creating a choice with empty text') {
      expect { create_choice(text: '') }.to(
          raise_error(Sequel::CheckConstraintViolation,
                      /violates check constraint "text_not_empty"/))
    }
  }

  context('destroy') {
    it('destroys itself from poll') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choices).to_not(be_empty)
      expect(choice.exists?).to(be(true))
      poll.remove_choice(choice)
      expect(poll.choices).to(be_empty)
      expect(choice.exists?).to(be(false))
    }

    it('rejects destroying from an expired poll') {
      choice = create_choice
      choice.poll.update(expiration: past)
      expect { choice.destroy }.to(
          raise_error(Sequel::HookFailed,
                      'Choice removed from expired poll'))
    }

    it('cascades destroy to responses') {
      choice = create_choice
      poll = choice.poll
      member = poll.group.add_member
      response = choice.add_response(member_id: member.id)
      expect(poll.responses).to_not(be_empty)
      expect(response.exists?).to(be(true))
      choice.destroy
      expect(poll.responses(reload: true)).to(be_empty)
      expect(response.exists?).to(be(false))
    }
  }

  context('add_response') {
    it('rejects adding a response to an expired poll') {
      choice = create_choice
      member = choice.poll.group.add_member
      choice.poll.update(expiration: past)
      expect { choice.add_response(member_id: member.id) }.to(
          raise_error(Sequel::HookFailed,
                      'Response modified in expired poll'))
    }

    it('rejects adding a response without a member') {
      choice = create_choice
      expect { choice.add_response(member_id: nil) }.to(
          raise_error(Sequel::NotNullConstraintViolation,
                      /null value in column "member_id"/))
    }
  }
}
