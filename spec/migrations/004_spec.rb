require 'securerandom'
require 'sequel'

RSpec.describe('004_add_api_key', type: :migration) {
  it('migrates up, giving every existing user an api key') {
    Sequel::Migrator.run(DB, 'db/migrations', target: 3)

    # Create some users with no api_key column at this point.
    10.times { DB[:users].insert(email: random_email) }
    DB[:users].each { |user| expect(user[:api_key]).to(be_nil) }

    # Migrate and find all users now have an api_key.
    Sequel::Migrator.run(DB, 'db/migrations', target: 4)
    DB[:users].each { |user| expect(user[:api_key].length).to(eq(24)) }
  }

  it('migrates down, dropping the api_key field') {
    Sequel::Migrator.run(DB, 'db/migrations', target: 4)

    # Create some users with an api_key.
    10.times {
      DB[:users].insert(email: random_email,
                        api_key: SecureRandom.alphanumeric(24))
    }
    DB[:users].each { |user| expect(user[:api_key].length).to(eq(24)) }

    # Migrate and find all users now have no api_key.
    Sequel::Migrator.run(DB, 'db/migrations', target: 3)
    DB[:users].each { |user| expect(user[:api_key]).to(be_nil) }
  }
}
