Sequel.migration {
  change {
    create_table(:polls) {
      String :id, primary_key: true
      String :title, null: false
    }
  }
}
