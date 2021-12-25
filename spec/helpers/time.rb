module RSpec
  module Time
    def future
      return ::Time.now + 10
    end

    def past
      return ::Time.now - 10
    end

    def freeze_time
      moment = ::Time.at(rand(::Time.now.to_i))
      allow(::Time).to(receive(:now).and_return(moment))
      return moment
    end
  end
end
