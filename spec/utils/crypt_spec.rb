require_relative '../../lib/utils/crypt'

RSpec.describe(Utils::Crypt) {
  it('encrypts and decrypts to the same thing') {
    expect(Utils::Crypt.de(Utils::Crypt.en('hello world')))
      .to(eq('hello world'))
  }
}
