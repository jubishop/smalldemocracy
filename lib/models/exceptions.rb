module Models
  class Error < ::StandardError
  end

  class ArgumentError < Error
  end

  class TypeError < Error
  end

  class RangeError < Error
  end
end
