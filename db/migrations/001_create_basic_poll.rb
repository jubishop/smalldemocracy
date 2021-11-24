Sequel.migration {
  change {
    create_enum(:poll_type, %w[borda_single borda_split choose_one])

    create_table(:polls) {
      uuid :id, primary_key: true, default: Sequel.function(:gen_random_uuid)

      String :title, null: false
      constraint(:title_not_empty) { Sequel.char_length(title) >= 1 }

      String :question, null: false
      constraint(:question_not_empty) { Sequel.char_length(question) >= 1 }

      Time :expiration, null: false

      poll_type :type, null: false, default: 'borda_single'
    }
  }
}
