Sequel.migration {
  up {
    add_column :responses, :data, :json
    self[:responses].map(%i[id score]).each { |response_id, score|
      self[:responses].where(id: response_id).update(
          data: Sequel.pg_json_wrap(score: score))
    }
    drop_column :responses, :score
  }
}
