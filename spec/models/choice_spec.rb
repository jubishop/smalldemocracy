require_relative '../../lib/models/choice'

RSpec.describe(Models::Choice, type: :model) {
  context('.create') {
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

  context('#destroy') {
    it('destroys itself from poll') {
      poll = create_poll
      choice = poll.add_choice
      expect(poll.choices).to_not(be_empty)
      expect(choice.exists?).to(be(true))
      poll.remove_choice(choice)
      expect(poll.choices).to(be_empty)
      expect(choice.exists?).to(be(false))
    }

    it('rejects destroying from poll with responses') {
      choice = create_choice
      choice.add_response(member_id: choice.poll.creating_member.id)
      expect { choice.destroy }.to(
          raise_error(Sequel::HookFailed,
                      'Choice removed in poll with responses'))
    }
  }

  context('#update') {
    it('rejects any updates') {
      choice = create_choice
      expect { choice.update(text: 'New text') }.to(
          raise_error(Sequel::HookFailed, 'Choices are immutable'))
    }
  }

  context('#responses') {
    it('finds all its responses') {
      choice = create_choice
      response = choice.add_response(member_id: choice.poll.creating_member.id)
      expect(choice.responses).to(match_array(response))
    }
  }

  context('#add_response') {
    it('rejects adding a response to an expired poll') {
      choice = create_choice
      member = choice.poll.group.add_member
      freeze_time(future + 1.day)
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

    it('rejects adding two responses from same member') {
      group = create_group
      member = group.add_member
      poll = group.add_poll
      choice = poll.add_choice
      choice.add_response(member_id: member.id)
      expect { choice.add_response(member_id: member.id) }.to(
          raise_error(Sequel::ConstraintViolation,
                      /violates unique constraint "response_unique"/))
    }
  }
}
