module Async
  def self.run
    Process.detach(Process.fork {
      yield
      Process.exit
    })
  end
end
