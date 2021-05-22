module Models
  class Error < StandardError
  end

  class ArgumentError < Error
  end

  class TypeError < Error
  end
end
