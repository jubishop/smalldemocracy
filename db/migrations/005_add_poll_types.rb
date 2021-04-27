Sequel.migration {
  change {
    alter_table(:polls) {
      add_column(:type, String, null: false, default: 'borda_single')
      add_constraint(:type_is_valid, type: %w[borda_single borda_split])
    }
  }
}
