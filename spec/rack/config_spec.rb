RSpec.describe('config.ru', type: :rack_test) {
  it('gives proper Cache-Control headers') {
    get '/main.css'
    expect(last_response.ok?).to(be(true))
    expect(last_response.headers['Cache-Control']).to(
        eq('public, max-age=31536000, immutable'))
  }
}
