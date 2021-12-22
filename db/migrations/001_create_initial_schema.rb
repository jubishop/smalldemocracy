Sequel.migration {
  change {
    create_table(:users) {
      String :email, primary_key: true
    }

    create_table(:groups) {
      primary_key :id
      foreign_key :user_id, :users, type: String

      String :name, null: false
      constraint(:name_not_empty) { Sequel.char_length(name) >= 1 }

      unique(%i[name user_id], name: :name_unique)
    }

    create_table(:members) {
      primary_key :id
      foreign_key :group_id, :groups, on_delete: :cascade, on_update: :cascade
      foreign_key :email, :users, type: String

      unique(%i[email group_id], name: :member_unique)
    }

    create_enum(:poll_type, %w[borda_single borda_split choose_one])

    create_table(:polls) {
      uuid :id, primary_key: true, default: Sequel.function(:gen_random_uuid)
      foreign_key :group_id, :groups, on_delete: :cascade, on_update: :cascade

      String :title, null: false
      constraint(:title_not_empty) { Sequel.char_length(title) >= 1 }

      String :question, null: false
      constraint(:question_not_empty) { Sequel.char_length(question) >= 1 }

      Time :expiration, null: false

      poll_type :type, null: false, default: 'borda_single'
    }

    create_table(:choices) {
      primary_key :id

      uuid :poll_id, null: false, index: true
      foreign_key [:poll_id], :polls, on_delete: :cascade, on_update: :cascade

      String :text, null: false
      unique(%i[poll_id text], name: :text_unique)
      constraint(:text_not_empty) { Sequel.char_length(text) >= 1 }
    }

    create_table(:responders) {
      primary_key :id

      uuid :poll_id, null: false, index: true
      foreign_key [:poll_id], :polls, on_delete: :cascade, on_update: :cascade

      String :email, null: false, index: true
      unique(%i[poll_id email], name: :email_unique)
      constraint(:email_not_empty) { Sequel.char_length(email) >= 1 }
    }

    create_table(:responses) {
      primary_key :id

      Integer :choice_id, null: false, index: true
      foreign_key [:choice_id], :choices, on_delete: :cascade,
                                          on_update: :cascade

      Integer :responder_id, null: false, index: true
      foreign_key [:responder_id], :responders, on_delete: :cascade,
                                                on_update: :cascade
      unique(%i[responder_id choice_id], name: :choice_unique)

      Integer :score
    }
  }
}
