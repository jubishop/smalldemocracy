require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

desc('Run all rspec tests')
RSpec::Core::RakeTask.new(:spec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.verbose
}

desc('Run spec excluding apparition tests')
RSpec::Core::RakeTask.new(:fspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t ~type:feature'
  t.verbose
}

desc('Run rspec_n (count:20)')
task(:rspec_n) {
  require 'colorize'
  require 'open3'

  ENV['FAIL_ON_GOLDEN'] = '1'

  puts 'Now running...'
  results = ''
  Open3.popen3('bundle exec rspec_n 20 -s') do |_, stderr, _, _|
    while (char = stderr.getc)
      results += char
      print(char)
    end
  end

  failures = results.uncolorize.match(/Runs Failed:\s+(\d+)/)[1].to_i
  if failures.positive?
    puts File.read(Dir['rspec_n_iteration*'].last)
  else
    puts 'All runs pass'.green
  end

  `rm rspec_n_iteration*`
}

task default: %w[rubocop:auto_correct spec]
task fast: %w[rubocop:auto_correct fspec]
