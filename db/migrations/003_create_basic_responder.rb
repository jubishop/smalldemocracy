Sequel.migration {
  change {
    create_table(:responders) {
      primary_key :id

      Integer :poll_id, null: false, index: true
      foreign_key [:poll_id], :polls, on_delete: :cascade, on_update: :cascade

      String :email, null: false, index: true
      unique %i[poll_id email]

      String :salt, null: false, index: true
      unique %i[poll_id salt]
      constraint(:salt_min_length) { Sequel.char_length(salt) >= 8 }
    }
  }
}
