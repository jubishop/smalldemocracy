require_relative 'env'

module RSpec
  class Goldens
    def self.verify(page, filename, **options)
      return if github_actions?

      base64 = page.driver.render_base64(:png, **options)

      unless File.exist?(base64_file(filename))
        warn("Creating new golden: #{filename}".light_red)
        write_goldens(page, filename, base64, **options)
        return
      end

      return if File.open(base64_file(filename)).read == base64

      warn("Golden match fail, replacing: #{filename}".red)
      write_goldens(page, filename, base64, **options)
    end

    class << self
      include RSpec::Matchers
      include RSpec::Env

      private

      def write_goldens(page, filename, base64, **options)
        File.write(base64_file(filename), base64)
        page.driver.save_screenshot(png_file(filename), **options)
        system("open #{png_file(filename)}")
      end

      def png_file(filename)
        File.join(golden_path, 'images', "#{filename}.png")
      end

      def base64_file(filename)
        File.join(golden_path, 'base64', filename)
      end

      def golden_path
        File.join(Dir.pwd, 'spec/goldens')
      end
    end
  end
end
