class Choice < Sequel::Model
  many_to_one :poll
end
