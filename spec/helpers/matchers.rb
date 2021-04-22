module Capybara
  module RSpecMatchers
    def have_fontawesome
      have_selector('.fontawesome-i2svg-complete')
    end

    def have_googlefonts
      have_selector('.google-fonts-loaded')
    end
  end
end
