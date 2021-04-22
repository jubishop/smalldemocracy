require 'git'

require_relative 'env'

module RSpec
  class Goldens
    def self.verify(page, filename, **options)
      return if github_actions?

      unless File.exist?(golden_file(filename))
        warn("Creating new golden: #{filename}".light_red)
        write_golden(page, filename, **options)
        system("open #{golden_file(filename)}")
        return
      end

      write_golden(page, filename, **options)
      return unless Git.open('.').diff.stats[:files].key?(golden_file(filename))

      warn("#{filename} appears to be modified".red)
      system("open #{golden_file(filename)}")
      return unless ENV.fetch('FAIL_ON_GOLDEN', false)

      raise RSpec::Expectations::ExpectationNotMetError,
            "#{filename} does not match"
    end

    class << self
      include Capybara::RSpecMatchers
      include RSpec::Env
      include RSpec::Matchers

      private

      def write_golden(page, filename, **options)
        expect(page).to(have_googlefonts)
        page.driver.save_screenshot(golden_file(filename), **options)
      end

      def golden_file(filename)
        return File.join('spec/goldens', "#{filename}.png")
      end
    end
  end
end
