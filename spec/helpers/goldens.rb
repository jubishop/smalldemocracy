require 'colorize'
require 'rspec'

module Tony
  class Goldens
    @failures = []
    def self.mark_failure(failure)
      @failures.push(failure)
    end

    def self.review_failures
      return if @failures.empty?
    end

    include Capybara::RSpecMatchers
    include RSpec::Matchers
    include ::Test::Env

    def initialize(page, goldens_folder = 'spec/goldens')
      @page = page
      @goldens_folder = goldens_folder
    end

    def verify(filename)
      return if github_actions?

      expect(@page).to(have_googlefonts)

      @page.driver.save_screenshot(tmp_file(filename), { full: true })

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

    private

    def apply_golden(filename)
      failure = GoldenFailure.new(golden: golden_file(filename),
                                  new: tmp_file(filename))
      self.class.mark_failure(failure)

      FileUtils.mv(tmp_file(filename), golden_file(filename))
      system("open #{golden_file(filename)}")
    end

    def golden_file(filename)
      return File.join(@goldens_folder, "#{filename}.png")
    end

    def tmp_file(filename)
      return File.join(Dir.tmpdir, "#{filename}.png")
    end

    class GoldenFailure
      def initialize(golden:, new:)
        @golden = golden
        @new = new
      end
    end
  end
end

RSpec.configure { |config|
  config.after(:suite) {
    Tony::Goldens.review_failures
  }
}
