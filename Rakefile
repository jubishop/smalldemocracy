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
}

task default: %w[rubocop:auto_correct spec]
