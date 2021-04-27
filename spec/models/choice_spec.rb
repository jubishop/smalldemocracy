require_relative '../../lib/models/choice'

RSpec.describe(Models::Choice) {
  context('::create') {
    it('successfully makes a basic choice') {
      poll = create_poll
      choice = poll.add_choice(text: 'text')
      expect(choice.text).to(eq('text'))
    }

    it('rejects making a choice with no poll associated') {
      expect { Models::Choice.create(text: 'text') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating two choices with the same text') {
      poll = create_poll
      poll.add_choice(text: 'text')
      expect { poll.add_choice(text: 'text') }.to(
          raise_error(Sequel::ConstraintViolation))
    }

    it('rejects creating a choice with empty text') {
      poll = create_poll
      expect { poll.add_choice(text: '') }.to(
          raise_error(Sequel::ConstraintViolation))
    }
  }
}
