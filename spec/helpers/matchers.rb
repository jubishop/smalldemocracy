require 'capybara/rspec'

module Tony
  module Test
    module Capybara
      module Matchers
        def have_assets
          have_selector('.page-fully-loaded')
        end

        def have_fonts
          have_selector('.fonts-fully-loaded')
        end

        def have_modal
          have_selector('.modal-is-open')
        end
      end
    end
  end
end

Capybara::RSpecMatchers.include(Tony::Test::Capybara::Matchers)
