def connect_sequel_db # rubocop:disable Style/TopLevelMethodDefinition
  case ENV.fetch('APP_ENV')
  when 'production'
    return Sequel.postgres(ENV.fetch('DATABASE_URL'))
  when 'development'
    return Sequel.postgres(database: 'smalldemocracy_dev')
  end
end

namespace :db do
  desc 'Run sequel migrations'
  task(:migrate, [:version]) { |_, args|
    version = args[:version].to_i if args[:version]
    require 'sequel/core'
    Sequel.extension(:migration)
    db = connect_sequel_db
    db.extension(:pg_enum)
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
  t.pattern = Dir.glob('spec/**/*_spec.rb')
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
  require 'sequel/core'
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
  files = (Dir['src/*/*'] - Dir['src/lib/*']).join(' ')
  `esbuild #{files} #{params}`
}

desc('Rebuild all public/ CSS and JS files')
task(:rebuild) {
  `rm -rf public/*~*.ico`
  Rake::Task[:sass].invoke
  Rake::Task[:esbuild].invoke
}

desc('Rebuild, watch, and launch localhost:8989')
task(:run) {
  `rm -rf public/*~*.ico`
  Thread.new { Rake::Task[:sass].invoke('--watch') }
  Thread.new { Rake::Task[:esbuild].invoke('--watch') }
  `bundle exec rackup -p 8989`
}

task models: %w[rubocop:auto_correct mspec]
task rack: %w[rubocop:auto_correct rspec]
task fast: %w[rubocop:auto_correct fspec]
task capybara: %w[rubocop:auto_correct rebuild cspec]
task default: %w[rubocop:auto_correct rebuild spec]
