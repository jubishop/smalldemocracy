require_relative 'development_helpers'

namespace :db do
  desc 'Run sequel migrations'
  task(:migrate, [:version]) { |_, args|
    version = args[:version].to_i if args[:version]
    require 'sequel/core'
    Sequel.extension(:migration)
    db = connect_sequel_db
    db.extension(:pg_enum)
    db.extension(:pg_json)
    Sequel::Migrator.run(db, 'db/migrations', target: version)
  }

  desc 'Clear database'
  task(:clear) {
    Rake::Task['db:migrate'].invoke(0)
  }
end

return if ENV.fetch('APP_ENV', 'test') == 'production'

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

desc('Run all tests')
RSpec::Core::RakeTask.new(:spec) { |t|
  ENV['FAIL_ON_GOLDEN'] = '1'
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.verbose
}

desc('Run spec on migrations')
RSpec::Core::RakeTask.new(:migration_spec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:migration'
  t.verbose
}

desc('Run spec on model tests')
RSpec::Core::RakeTask.new(:mspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:model'
  t.verbose
}

desc('Run spec on rack tests')
RSpec::Core::RakeTask.new(:rspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:rack_test'
  t.verbose
}

desc('Run spec excluding capybara tests')
RSpec::Core::RakeTask.new(:fspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t ~type:feature'
  t.verbose
}

desc('Run spec on capybara tests')
RSpec::Core::RakeTask.new(:cspec) { |t|
  ENV['FAIL_ON_GOLDEN'] = '1'
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:feature'
  t.verbose
}

desc('Run spec on capybara tests and create new goldens for failures')
RSpec::Core::RakeTask.new(:gspec) { |t|
  ENV.delete('FAIL_ON_GOLDEN')
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:feature'
  t.verbose
}

# rubocop:disable Style/TopLevelMethodDefinition
def rspec_n(count: 50, type: nil)
  require 'colorize'
  require 'open3'

  ENV['FAIL_ON_GOLDEN'] = '1'
  count ||= 50
  type = type ? " -t type:#{type}" : ''

  puts 'Now running...'.green
  cmd = "bundle exec rspec_n #{count} -c 'bundle exec rspec#{type}' -s"
  Open3.popen2e(cmd) do |_, stdout_and_stderr, _|
    while (char = stdout_and_stderr.getc)
      print(char)
    end
  end
end
# rubocop:enable Style/TopLevelMethodDefinition

desc('Run rspec_n on all tests')
task(:spec_n, [:count]) { |_, args|
  rspec_n(count: args[:count])
}

desc('Run rspec_n on model tests')
task(:mspec_n, [:count]) { |_, args|
  rspec_n(count: args[:count], type: 'model')
}

desc('Run rspec_n on rack tests')
task(:rspec_n, [:count]) { |_, args|
  rspec_n(count: args[:count], type: 'rack_test')
}

desc('Run rspec_n excluding capybara tests')
task(:fspec_n, [:count]) { |_, args|
  rspec_n(count: args[:count], type: '~feature')
}

desc('Run rspec_n on capybara tests')
task(:cspec_n, [:count]) { |_, args|
  rspec_n(count: args[:count], type: 'feature')
}

desc('Annotate sequel classes')
task(:annotate) {
  connect_sequel_db
  Dir['lib/models/*.rb'].each { |file| require_relative file }
  require 'sequel/annotate'
  Sequel::Annotate.annotate(Dir['lib/models/*.rb'], namespace: 'Models',
                                                    position: :before)
}

desc('Compile all SCSS files from scss/ into public/')
task(:sass, [:params]) { |_, args|
  params = args[:params].to_s
  params += ' --style=compressed --no-source-map'
  `sass #{params} scss:public`
}

desc('Bundle all JS files from src/ into public/')
task(:esbuild, [:params]) { |_, args|
  params = args[:params].to_s
  params += ' --bundle --format=esm --outdir=public'
  files = (Dir['src/**/*.js'] - Dir['src/lib/*.js']).join(' ')
  `esbuild #{files} #{params}`
}

desc('Remove all public/ CSS and JS files')
task(:clear) {
  `find -E public -type f -regex ".+[js|css]$" -delete`
}

desc('Remove then rebuild all public/ CSS and JS files')
task(:rebuild) {
  Rake::Task[:clear].invoke
  Rake::Task[:sass].invoke
  Rake::Task[:esbuild].invoke
}

desc('Rebuild, watch, and launch localhost:8989')
task(:run, [:port]) { |_, args|
  port = args[:port]
  port ||= 8989

  stub_environment_vars('development')

  Rake::Task[:clear].invoke
  Thread.new { Rake::Task[:sass].invoke('--watch') }
  Thread.new { Rake::Task[:esbuild].invoke('--watch') }

  require 'colorize'
  require 'open3'
  Open3.popen2e("bundle exec rackup -p #{port}") do |_, stdout_and_stderr, _|
    while (char = stdout_and_stderr.getc)
      print(char)
    end
  end
}

task migrations: %w[migration_spec]
task models: %w[mspec]
task rack: %w[rspec]
task fast: %w[fspec]
task capybara: %w[rebuild cspec]
task goldens: %w[gspec]
task default: %w[rubocop:auto_correct rebuild spec]
