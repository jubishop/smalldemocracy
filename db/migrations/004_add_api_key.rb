require 'securerandom'

Sequel.migration {
  up {
    alter_table(:users) {
      add_column :api_key, String, unique: true, index: true
    }
    self[:users].select(:email).each { |user|
      self[:users].where(email: user[:email]).update(
          api_key: SecureRandom.alphanumeric(24))
    }
    alter_table(:users) {
      set_column_not_null :api_key
    }
  }

  down {
    drop_column :users, :api_key
  }
}
