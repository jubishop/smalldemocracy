Sequel.migration {
  change {
    alter_table(:responses) {
      add_column(:chosen, TrueClass)
    }
  }
}
