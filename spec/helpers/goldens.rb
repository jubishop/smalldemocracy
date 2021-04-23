require_relative 'env'

module RSpec
  class Goldens
    def self.verify(page, filename, **options)
      return if github_actions?

      expect(page).to(have_googlefonts)

      unless File.exist?(base64_file(filename))
        warn("Creating new golden for: #{filename}".light_red)
        write_golden(page, filename, **options)
        system("open #{golden_file(filename)}")
        return
      end

      golden_base64 = File.read(base64_file(filename))
      new_base64 = page.driver.render_base64(:png, **options)
      return if golden_base64 == new_base64

      warn("Golden match failed for: #{filename}".red)
      write_golden(page, filename, **options)
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
        File.write(base64_file(filename),
                   page.driver.render_base64(:png, **options))
        page.driver.save_screenshot(golden_file(filename), **options)
      end

      def golden_file(filename)
        return File.join('spec/goldens', "#{filename}.png")
      end

      def base64_file(filename)
        return File.join('spec/goldens/base64', filename)
      end
    end
  end
end
