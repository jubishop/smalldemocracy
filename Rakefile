namespace :db do
  desc 'Run migrations'
  task(:migrate, [:version]) { |_, args|
    require 'sequel/core'

    Sequel.extension(:migration)
    version = args[:version].to_i if args[:version]

    db = case ENV.fetch('APP_ENV')
         when 'production'
           Sequel.postgres(ENV.fetch('DATABASE_URL'))
         when 'development'
           Sequel.postgres(database: 'smalldemocracy_dev')
         end

    db.extension(:pg_enum)
    Sequel::Migrator.run(db, 'db/migrations', target: version)
  }

  desc 'Clear DB'
  task(:clear) {
    Rake::Task['db:migrate'].invoke(0)
  }
end

return if ENV.fetch('APP_ENV') == 'production'

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

desc('Run all rspec tests')
RSpec::Core::RakeTask.new(:spec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.verbose
}

desc('Run spec excluding capybara tests')
RSpec::Core::RakeTask.new(:fspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t ~type:feature'
  t.verbose
}

desc('Run rspec_n ')
task(:rspec_n, [:count]) { |_, args|
  require 'colorize'
  require 'open3'

  ENV['FAIL_ON_GOLDEN'] = '1'
  count = args[:count] ? args[:count].to_i : 20

  puts 'Now running...'
  results = ''
  Open3.popen3("bundle exec rspec_n #{count} -s") do |_, stderr, _, _|
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
