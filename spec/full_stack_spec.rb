require 'rack'

RSpec.describe('Full stack config.ru') {
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  context('/') {
    it('responds to / with OK status') {
      get '/'
      expect(last_response.ok?).to(be(true))
    }

    it('redirects to https in production only') {
      ENV['RACK_ENV'] = 'production'
      get '/', nil, { FLY_FORWARDED_PROTO: 'http' }

      expect(last_request.ssl?).to(be(false))
      expect(last_response.redirect?).to(be(true))

      follow_redirect!
      expect(last_request.ssl?).to(be(true))
    }
  }
}
