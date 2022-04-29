module Helpers
  module Env
    def on_prod?
      return ENV.fetch('ON_PROD', false)
    end
  end
end
