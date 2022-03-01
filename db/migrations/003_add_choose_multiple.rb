Sequel.migration {
  up {
    add_enum_value :poll_type, 'choose_multiple'
    add_column :polls, :data, :json
  }
}
