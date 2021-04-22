require 'chunky_png'

require_relative 'env'

module RSpec
  class Goldens
    def self.verify(page, filename, **options)
      return if github_actions?

      unless File.exist?(golden_file(filename))
        warn("Creating new golden: #{filename}".light_red)
        write_goldens(page, filename, **options)
        return
      end

      page.driver.save_screenshot(tmp_file(filename), **options)
      golden_screenshot = ChunkyPNG::Image.from_file(golden_file(filename))
      new_screenshot = ChunkyPNG::Image.from_file(tmp_file(filename))
      0.upto(golden_screenshot.height - 1) { |y|
        golden_screenshot.row(y).each_with_index { |pixel, x|
          next if pixel == new_screenshot[x, y]

          warn("Fail at pixel [#{x}, #{y}] replacing: #{filename}".red)
          write_goldens(page, filename, **options)
          return true
        }
      }
    end

    class << self
      include RSpec::Matchers
      include RSpec::Env

      private

      def write_goldens(page, filename, **options)
        page.driver.save_screenshot(golden_file(filename), **options)
        system("open #{golden_file(filename)}")
        return unless ENV.fetch('FAIL_ON_GOLDEN', false)

        raise RSpec::Expectations::ExpectationNotMetError,
              "#{filename} does not match"
      end

      def tmp_file(filename)
        return File.join(ENV.fetch('TMPDIR', '/tmp'), "#{filename}.png")
      end

      def golden_file(filename)
        return File.join(Dir.pwd, 'spec/goldens', "#{filename}.png")
      end
    end
  end
end
