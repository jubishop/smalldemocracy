require 'colorize'
require 'open3'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_, args|
    require 'sequel/core'
    Sequel.extension(:migration)
    version = args[:version].to_i if args[:version]
    Sequel.connect('sqlite://.data/db.sqlite') do |db|
      Sequel::Migrator.run(db, 'db/migrations', target: version)
    end
  end
  task :clear do |_|
    Rake::Task['db:migrate'].invoke(0)
  end
end

RuboCop::RakeTask.new(:rubocop)
RSpec::Core::RakeTask.new(:spec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.verbose
}

desc('Run rspec_n [count=20]')
task(:rspec_n, [:count]) { |_, args|
  args.with_defaults(count: 20)

  puts 'Now running...'
  results = ''
  Open3.popen3("bundle exec rspec_n #{args[:count]} -s") do |_, stderr, _, _|
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
