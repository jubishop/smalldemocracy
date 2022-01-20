require 'sequel'

require_relative '../../lib/models/response'

RSpec.describe('002_move_score_to_json', type: :migration) {
  before(:each) {
    Sequel::Migrator.run(DB, 'db/migrations', target: 1)
  }

  it('migrates score into json blob') {
    # Manually and painfully create a bunch of responses, putting values into
    # the old `Response.score` field.
    responses = {} # Key = response_id, Value = score.
    3.times {
      email = DB[:users].insert(email: random_email)
      3.times { |group_name|
        group_id = DB[:groups].insert(name: group_name, email: email)
        members = Array.new(3).fill {
          email = random_email
          DB[:users].insert(email: email)
          DB[:members].insert(group_id: group_id, email: email)
        }
        3.times {
          poll_id = DB[:polls].insert(email: email,
                                      group_id: group_id,
                                      created_at: Time.now,
                                      updated_at: Time.now,
                                      title: 'title',
                                      question: 'question',
                                      expiration: future,
                                      type: 'borda_single')
          3.times { |choice_text|
            choice_id = DB[:choices].insert(poll_id: poll_id, text: choice_text)
            3.times { |member_index|
              score = rand(1000)
              response_id = DB[:responses].insert(
                  choice_id: choice_id,
                  member_id: members[member_index],
                  score: score)
              responses[response_id] = score
            }
          }
        }
      }
    }

    # Migrate and find all responses now in blob['score']
    Sequel::Migrator.run(DB, 'db/migrations', target: 2)
    responses.each { |response_id, score|
      response = DB[:responses].first(id: response_id)
      expect(response[:blob]['score']).to(eq(score))
      expect(response[:score]).to(be_nil)
    }
  }
}
