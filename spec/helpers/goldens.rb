require 'git'

require_relative 'env'

module RSpec
  class Goldens
    @@git = Git.open('.')

    def self.verify(page, filename, **options)
      return if github_actions?

      unless File.exist?(golden_file(filename))
        warn("Creating new golden: #{filename}".light_red)
        write_golden(page, filename, **options)
        @@git.add(golden_file(filename))

        return unless ENV.fetch('FAIL_ON_GOLDEN', false)

        raise RSpec::Expectations::ExpectationNotMetError,
              "#{filename} does not exist"
      end

      write_golden(page, filename, **options)
      return unless @@git.diff.stats.key?(golden_file(filename))

      warn("Failed match on #{filename}".red)
      return unless ENV.fetch('FAIL_ON_GOLDEN', false)

      raise RSpec::Expectations::ExpectationNotMetError,
            "#{filename} does not match"
    end

    class << self
      include RSpec::Matchers
      include RSpec::Env

      private

      def write_golden(page, filename, **options)
        page.driver.save_screenshot(golden_file(filename), **options)
        system("open #{golden_file(filename)}")
        return unless ENV.fetch('FAIL_ON_GOLDEN', false)

        raise RSpec::Expectations::ExpectationNotMetError,
              "#{filename} does not match"
      end

      def golden_file(filename)
        return File.join('spec/goldens', "#{filename}.png")
      end
    end
  end
end
