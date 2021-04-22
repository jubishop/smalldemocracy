RSpec.describe('Full stack config.ru') {
  include_context(:rack_test)

  context('/') {
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
