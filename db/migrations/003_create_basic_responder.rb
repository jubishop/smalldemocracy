Sequel.migration {
  change {
    create_table(:responders) {
      primary_key :id

      uuid :poll_id, null: false, index: true
      foreign_key [:poll_id], :polls, on_delete: :cascade, on_update: :cascade

      String :email, null: false, index: true
      unique(%i[poll_id email], name: :email_unique)
      constraint(:email_not_empty) { Sequel.char_length(email) >= 1 }
    }
  }
}
