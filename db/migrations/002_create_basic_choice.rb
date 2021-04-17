Sequel.migration {
  change {
    create_table(:choices) {
      primary_key :id

      Integer :poll_id, null: false, index: true
      foreign_key [:poll_id], :polls, on_delete: :cascade, on_update: :cascade

      String :text, null: false
      unique %i[poll_id text]
    }
  }
}
