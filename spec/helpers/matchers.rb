require 'capybara/rspec'

module Tony
  module Test
    module Capybara
      module Matchers
      end
    end
  end
end

Capybara::RSpecMatchers.include(Tony::Test::Capybara::Matchers)
