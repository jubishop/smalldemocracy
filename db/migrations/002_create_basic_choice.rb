Sequel.migration {
  change {
    create_table(:choices) {
      primary_key :id
      foreign_key :poll_id, :polls, on_delete: :cascade, on_update: :cascade
      String :choice, null: false
      unique %i[poll_id choice]
    }
  }
}
