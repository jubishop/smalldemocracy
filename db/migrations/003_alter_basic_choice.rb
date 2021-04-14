Sequel.migration {
  change {
    alter_table(:choices) {
      rename_column :choice, :text
    }
  }
}
