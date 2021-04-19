Sequel.migration {
  change {
    create_table(:polls) {
      String :id, primary_key: true
      constraint(:id_min_length) { Sequel.char_length(id) >= 16 }

      String :title, null: false
      String :question, null: false
      Integer :expiration, null: false
    }
  }
}
