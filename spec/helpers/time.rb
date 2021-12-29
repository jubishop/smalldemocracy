module RSpec
  module Time
    def future
      return ::Time.at((::Time.now + 99).to_i / 60 * 60)
    end

    def past
      return ::Time.at((::Time.now - 99).to_i / 60 * 60)
    end

    def random_time
      return ::Time.at(rand(::Time.now.to_i) / 60 * 60)
    end

    def freeze_time(moment: random_time)
      allow(::Time).to(receive(:now).and_return(moment))
      return moment
    end
  end
end

class Time
  def form
    return strftime('%Y-%m-%dT%H:%M')
  end
end
