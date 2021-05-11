require 'puma'
require 'puma/configuration'
require 'puma/events'
require 'rack'
require 'tony'

module Tony
  module Test
    module Goldens
      class Server
        def initialize(failures)
          return if failures.empty?

          app = Tony::App.new
          slim = Tony::Slim.new(views: __dir__)
          server = ::Rack::Builder.new {
            use(Tony::Static, public_folder: '/')
            run(app)
          }
          conf = Puma::Configuration.new { |user_config|
            user_config.app(server)
            user_config.port(0)
          }
          events = Puma::Events.new($stdout, $stderr)
          launcher = Puma::Launcher.new(conf, events: events)

          app.get('/', ->(_, resp) {
            resp.write(slim.render(:review, failures: failures))
          })

          app.get('/finished', ->(_, resp) {
            launcher.stop
            resp.write('All done...please close this window.')
          })

          events.on_booted {
            system("open http://localhost:#{launcher.connected_ports.first}")
          }

          launcher.run
        end
      end
    end
  end
end
