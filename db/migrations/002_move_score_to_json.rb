Sequel.migration {
  up {
    add_column :responses, :blob, :json
    responses = self[:responses]
    responses.map(%i[id score]).each { |response_id, score|
      responses.where(id: response_id).update(
          blob: Sequel.pg_json_wrap(score: score))
    }
    drop_column :responses, :score
  }
}
