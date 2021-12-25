module RSpec
  module Time
    def future
      return ::Time.now + 99
    end

    def past
      return ::Time.now - 99
    end

    def random_time
      return ::Time.at(rand(::Time.now.to_i))
    end

    def freeze_time
      moment = random_time
      allow(::Time).to(receive(:now).and_return(moment))
      return moment
    end
  end
end
