require 'duration'

module RSpec
  module Time
    def future
      return (::Time.now + 55.minutes).round_down
    end

    def past
      return (::Time.now - 55.minutes).round_down
    end

    def random_time
      return ::Time.at(rand(2**31)).round_down
    end

    def freeze_time(moment = random_time)
      allow(::Time).to(receive(:now).and_return(moment))
      return moment
    end
  end
end

class Time
  # Asia/Bangkok => +07:00
  def form(in_zone: '+07:00')
    return self.class.at(self, in: in_zone).strftime('%Y-%m-%dT%H:%M')
  end

  def round_down
    return self.class.at(to_i / 60 * 60)
  end
end
