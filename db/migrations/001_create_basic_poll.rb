Sequel.migration {
  change {
    create_table(:polls) {
      String :id, primary_key: true
      constraint(:id_min_length) { Sequel.char_length(id) >= 16 }

      String :title, null: false
      constraint(:title_not_empty) { Sequel.char_length(title) >= 1 }

      String :question, null: false
      constraint(:question_not_empty) { Sequel.char_length(question) >= 1 }

      Integer :expiration, null: false

      String :type, null: false, default: 'borda_single'
      constraint(:type_is_valid, type: %w[borda_single borda_split yes_or_no])
    }
  }
}
