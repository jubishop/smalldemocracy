module RSpec
  module Env
    def github_actions?
      return ENV.key?('CI')
    end
  end
end
