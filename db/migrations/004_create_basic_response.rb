Sequel.migration {
  change {
    create_table(:responses) {
      primary_key :id

      Integer :choice_id, null: false, index: true
      foreign_key [:choice_id], :choices, on_delete: :cascade,
                                          on_update: :cascade

      Integer :responder_id, null: false, index: true
      foreign_key [:responder_id], :responders, on_delete: :cascade,
                                                on_update: :cascade
      unique(%i[responder_id choice_id], name: :choice_unique)

      Integer :rank, null: false
      unique(%i[responder_id rank], name: :rank_unique)

      TrueClass :chosen
    }
  }
}
