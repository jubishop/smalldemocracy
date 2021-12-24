Sequel.migration {
  change {
    # TODO: Test simple successful creation of every model's attributes.
    create_table(:users) {
      String :email, primary_key: true
    }

    create_table(:groups) {
      primary_key :id
      foreign_key :email, :users, type: String, null: false
      String :name, null: false
      constraint(:name_not_empty) { Sequel.char_length(name) >= 1 }
      unique(%i[name email], name: :group_unique)
    }

    create_table(:members) {
      primary_key :id
      foreign_key :email, :users, type: String, null: false
      foreign_key :group_id, :groups, null: false, on_delete: :cascade
      unique(%i[email group_id], name: :member_unique)
    }

    create_enum(:poll_type, %w[borda_single borda_split choose_one])

    create_table(:polls) {
      uuid :id, primary_key: true, default: Sequel.function(:gen_random_uuid)
      foreign_key :email, :users, type: String, null: false
      foreign_key :group_id, :groups, null: false, on_delete: :cascade
      String :title, null: false
      constraint(:title_not_empty) { Sequel.char_length(title) >= 1 }
      String :question, null: false
      constraint(:question_not_empty) { Sequel.char_length(question) >= 1 }
      Time :expiration, null: false
      poll_type :type, null: false, default: 'borda_single'
    }

    create_table(:choices) {
      primary_key :id
      foreign_key :poll_id, :polls, type: :uuid,
                                    null: false,
                                    on_delete: :cascade
      String :text, null: false
      constraint(:text_not_empty) { Sequel.char_length(text) >= 1 }
      unique(%i[poll_id text], name: :choice_unique)
    }

    create_table(:responses) {
      primary_key :id
      foreign_key :choice_id, :choices, null: false, on_delete: :cascade
      foreign_key :member_id, :members, null: false, on_delete: :cascade
      unique(%i[member_id choice_id], name: :response_unique)
      Integer :score
    }
  }
}
