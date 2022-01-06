module RSpec
  module Time
    def future
      return (::Time.now + 99).round_down
    end

    def past
      return (::Time.now - 99).round_down
    end

    def random_time
      return ::Time.at(rand(::Time.now.to_i)).round_down
    end

    def freeze_time(moment = random_time)
      allow(::Time).to(receive(:now).and_return(moment))
      return moment
    end
  end
end

class Time
  def form
    return strftime('%Y-%m-%dT%H:%M')
  end

  def round_down
    return self.class.at(to_i / 60 * 60)
  end
end
