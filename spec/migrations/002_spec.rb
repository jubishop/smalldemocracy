require 'sequel'

RSpec.describe('002_move_score_to_json', type: :migration) {
  it('migrates up, putting score into data[:score]') {
    Sequel::Migrator.run(DB, 'db/migrations', target: 1)

    # Create responses with values in the old `Response.score` field.
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
            2.times { |member_index|
              score = rand(1000)
              response_id = DB[:responses].insert(
                  choice_id: choice_id,
                  member_id: members[member_index],
                  score: score)
              responses[response_id] = score
            }
            # One with no score
            DB[:responses].insert(
              choice_id: choice_id,
              member_id: members[2])
          }
        }
      }
    }

    # Migrate and find all responses now in `Response.data['score']`.
    Sequel::Migrator.run(DB, 'db/migrations', target: 2)
    responses.each { |response_id, score|
      response = DB[:responses].first(id: response_id)
      expect(response[:data]['score']).to(eq(score))
      expect(response[:score]).to(be_nil)
    }
  }

  it('migrates down, putting data[:score] into score') {
    Sequel::Migrator.run(DB, 'db/migrations', target: 2)

    # Create responses with values in the new `Response.data[:score]` field.
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
            2.times { |member_index|
              score = rand(1000)
              response_id = DB[:responses].insert(
                  choice_id: choice_id,
                  member_id: members[member_index],
                  data: Sequel.pg_json_wrap(score: score))
              responses[response_id] = score
            }
            # One with no data
            response_id = DB[:responses].insert(
                choice_id: choice_id,
                member_id: members[2])
          }
        }
      }
    }

    # Migrate and find all responses now in `Response.data['score']`.
    Sequel::Migrator.run(DB, 'db/migrations', target: 1)
    responses.each { |response_id, score|
      response = DB[:responses].first(id: response_id)
      expect(response[:score]).to(eq(score))
      expect(response[:data]).to(be_nil)
    }
  }
}
