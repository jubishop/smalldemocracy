module RSpec
  module Goldens
    class Page
      include ::Capybara::RSpecMatchers
      include ::RSpec::Matchers

      def initialize(page, goldens_folder = 'spec/goldens')
        @capybara_page = page
        @goldens_page = Tony::Test::Goldens::Page.new(page, goldens_folder)
      end

      def verify(filename)
        expect(@capybara_page).to(have_selector('.page-fully-loaded'))
        expect(@capybara_page).to(have_fontawesome)
        @goldens_page.verify(filename)
      end
    end
  end
end
