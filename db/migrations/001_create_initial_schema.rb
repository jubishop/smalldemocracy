Sequel.migration {
  change {
    create_table(:users) {
      String :email, primary_key: true
    }

    create_table(:groups) {
      primary_key :id, type: :Bignum
      foreign_key :email, :users, type: String, null: false
      String :name, null: false
      constraint(:name_not_empty) { Sequel.char_length(name) >= 1 }
      unique(%i[name email], name: :group_unique)
    }

    create_table(:members) {
      primary_key :id, type: :Bignum
      foreign_key :email, :users, type: String, null: false
      foreign_key :group_id, :groups, type: :Bignum,
                                      null: false,
                                      on_delete: :cascade
      unique(%i[email group_id], name: :member_unique)
    }

    create_enum(:poll_type, %w[borda_single borda_split choose_one])

    create_table(:polls) {
      primary_key :id, type: :Bignum
      foreign_key :email, :users, type: String, null: false
      foreign_key :group_id, :groups, type: :Bignum,
                                      null: false,
                                      on_delete: :cascade
      Time :created_at, null: false
      Time :updated_at, null: false
      String :title, null: false
      constraint(:title_not_empty) { Sequel.char_length(title) >= 1 }
      String :question, null: false
      constraint(:question_not_empty) { Sequel.char_length(question) >= 1 }
      Time :expiration, null: false
      poll_type :type, null: false
    }

    create_table(:choices) {
      primary_key :id, type: :Bignum
      foreign_key :poll_id, :polls, type: :Bignum,
                                    null: false,
                                    on_delete: :cascade
      String :text, null: false
      constraint(:text_not_empty) { Sequel.char_length(text) >= 1 }
      unique(%i[poll_id text], name: :choice_unique)
    }

    create_table(:responses) {
      primary_key :id, type: :Bignum
      foreign_key :choice_id, :choices, type: :Bignum,
                                        null: false,
                                        on_delete: :cascade
      foreign_key :member_id, :members, type: :Bignum,
                                        null: false,
                                        on_delete: :cascade
      unique(%i[member_id choice_id], name: :response_unique)
      Integer :score
    }
  }
}
