require 'colorize'

module RSpec
  class Goldens
    def self.verify(page, filename, **options)
      return if github_actions?

      options = { full: true } if options.empty?
      expect(page).to(have_googlefonts)

      page.driver.save_screenshot(tmp_file(filename), **options)

      unless File.exist?(golden_file(filename))
        apply_golden(filename)
        return
      end

      golden_bytes = File.read(golden_file(filename), mode: 'rb')
      new_bytes = File.read(tmp_file(filename), mode: 'rb')
      return if golden_bytes == new_bytes

      warn("Golden match failed for: #{filename}".red)
      apply_golden(filename)
      return unless ENV.fetch('FAIL_ON_GOLDEN', false)

      raise RSpec::Expectations::ExpectationNotMetError,
            "#{filename} does not match"
    end

    def self.view(page, filename, **options)
      expect(page).to(have_googlefonts)
      page.driver.save_screenshot(tmp_file(filename), **options)
      system("open #{tmp_file(filename)}")
    end

    class << self
      include Capybara::RSpecMatchers
      include Test::Env
      include RSpec::Matchers

      private

      def apply_golden(filename)
        FileUtils.mv(tmp_file(filename), golden_file(filename))
        system("open #{golden_file(filename)}")
      end

      def golden_file(filename)
        return File.join('spec/goldens', "#{filename}.png")
      end

      def tmp_file(filename)
        return File.join(Dir.tmpdir, "#{filename}.png")
      end
    end
  end
end
