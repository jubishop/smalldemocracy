def connect_sequel_db # rubocop:disable Style/TopLevelMethodDefinition
  case ENV.fetch('APP_ENV')
  when 'production'
    return Sequel.postgres(ENV.fetch('DATABASE_URL'))
  when 'development'
    return Sequel.postgres(database: 'smalldemocracy_dev')
  end
end

namespace :db do
  desc 'Run migrations'
  task(:migrate, [:version]) { |_, args|
    version = args[:version].to_i if args[:version]
    require 'sequel/core'
    Sequel.extension(:migration)
    db = connect_sequel_db
    db.extension(:pg_enum)
    Sequel::Migrator.run(db, 'db/migrations', target: version)
  }

  desc 'Clear DB'
  task(:clear) {
    Rake::Task['db:migrate'].invoke(0)
  }
end

return if ENV.fetch('APP_ENV', 'test') == 'production'

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

desc('Run all rspec tests')
RSpec::Core::RakeTask.new(:spec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.verbose
}

desc('Run spec only model tests')
RSpec::Core::RakeTask.new(:mspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:model'
  t.verbose
}

desc('Run spec only rack tests')
RSpec::Core::RakeTask.new(:rspec) { |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '-t type:rack_test'
  t.verbose
}

desc('Run spec only capybara tests')
RSpec::Core::RakeTask.new(:cspec) { |t|
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

  puts 'Now running...'
  results = ''
  cmd = "bundle exec rspec_n #{count} -c 'bundle exec rspec#{type}' -s"
  Open3.popen3(cmd) do |_, stderr, _, _|
    while (char = stderr.getc)
      results += char
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

desc('Run rspec_n on capybara tests')
task(:cspec_n, [:count]) { |_, args|
  rspec_n(count: args[:count], type: 'feature')
}

desc('Annotate sequel classes')
task(:annotate) {
  require 'sequel/core'
  connect_sequel_db
  Dir['lib/models/*.rb'].each { |file| require_relative file }
  require 'sequel/annotate'
  Sequel::Annotate.annotate(Dir['lib/models/*.rb'], namespace: 'Models',
                                                    position: :before)
}

desc('Compile all scss files to compressed css')
task(:sass, [:params]) { |_, args|
  params = args[:params].to_s
  params += ' --style=compressed --no-source-map'
  `sass #{params} scss:public`
}

desc('Run esbuild over all JS files')
task(:esbuild, [:params]) { |_, args|
  params = args[:params].to_s
  params += ' --bundle --format=esm --outdir=public --outbase=src'
  files = (Dir['src/*/*'] - Dir['src/lib/*']).join(' ')
  `esbuild #{files} #{params}`
}

desc('Compile css and launch localhost:8989')
task(:run) {
  Thread.new { Rake::Task[:sass].invoke('--watch') }
  Thread.new { Rake::Task[:esbuild].invoke('--watch') }
  `bundle exec rackup -p 8989`
}

task build: %w[rubocop:auto_correct sass esbuild]
task default: %w[build spec]
task models: %w[build mspec]
task rack: %w[build rspec]
task capybara: %w[build cspec]
