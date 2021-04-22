module Capybara
  module RSpecMatchers
    def have_fontawesome
      have_selector('.fontawesome-i2svg-complete')
    end
  end
end
