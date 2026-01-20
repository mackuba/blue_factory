##
# Namespace for error types raised by BlueFactory.
module BlueFactory
  ##
  # Raised when authentication is missing or invalid.
  class AuthorizationError < StandardError
    # @return [String, nil] the error type identifier for response payloads
    attr_reader :error_type

    # @param message [String] human-friendly error description
    # @param error_type [String, nil] optional error code for the client
    def initialize(message = "Authentication required", error_type = nil)
      super(message)
      @error_type = error_type
    end
  end

  ##
  # Raised when feed keys fail validation.
  class InvalidKeyError < StandardError
  end

  ##
  # Raised when a request is malformed or missing required parameters.
  class InvalidRequestError < StandardError
    # @return [String, nil] the error type identifier for response payloads
    attr_reader :error_type

    # @param message [String] human-friendly error description
    # @param error_type [String, nil] optional error code for the client
    def initialize(message, error_type = nil)
      super(message)
      @error_type = error_type
    end
  end

  ##
  # Raised when a feed response does not match the expected shape.
  class InvalidResponseError < StandardError
  end

  ##
  # Raised when a feed class exposes an unexpected API.
  class InvalidFeedClassError < StandardError
  end

  ##
  # Raised when a feed URI references an unsupported algorithm.
  class UnsupportedAlgorithmError < StandardError
  end
end
