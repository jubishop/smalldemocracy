require 'rack/test'

require_relative '../setup'
require_relative '../lib/main'

RSpec.describe(Main) {
  include Rack::Test::Methods

  let(:app) { Main }

  it('responds to / with OK status') {
    get '/'
    expect(last_response.ok?).to(be(true))
  }
}
