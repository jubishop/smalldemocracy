require 'capybara/rspec'

module Tony
  module Test
    module Capybara
      module Matchers
        def have_sortable_js
          have_button(text: 'Submit Choices')
        end
      end
    end
  end
end

Capybara::RSpecMatchers.include(Tony::Test::Capybara::Matchers)
