require_relative '../lib/utils/crypt'

RSpec.describe(Crypt) {
  it('encrypts and decrypts to the same thing') {
    expect(Crypt.de(Crypt.en('hello world'))).to(eq('hello world'))
  }
}
