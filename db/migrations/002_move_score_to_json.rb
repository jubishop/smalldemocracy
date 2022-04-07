Sequel.migration {
  up {
    add_column :responses, :data, :json
    self[:responses].select(:id, :score).each { |response|
      self[:responses].where(id: response[:id]).update(
          data: Sequel.pg_json_wrap(score: response[:score]))
    }
    drop_column :responses, :score
  }

  down {
    add_column :responses, :score, Integer
    self[:responses].select(:id, :data).each { |response|
      self[:responses].where(id: response[:id]).update(
          score: response.dig(:data, 'score'))
    }
    drop_column :responses, :data
  }
}
