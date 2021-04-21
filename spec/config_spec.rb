require 'rack'
require 'rack/test'

RSpec.describe('config.ru') {
  include Rack::Test::Methods

  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it('responds to / with OK status') {
    get '/'
    expect(last_response.ok?).to(be(true))
  }
}
