module RSpec
  module EMail
    def random_email
      return "#{rand}@#{rand}"
    end
  end
end

class String
  def to_email(domain = 'email.com')
    "#{tr(' :', '_')}@#{domain}"
  end
end
