module BlueFactory

  #
  # Raised during request processing if the authorization token can't be parsed; it can also be
  # thrown from the user's {FeedHandler#get_posts} method to indicate that the given user is not
  # authorized to access the requested feed, or that the feed requires authentication and it wasn't
  # provided.
  #
  # The server intercepts this exception and returns a "401 Unauthorized" response to the AppView,
  # which should result in the app displaying an error banner (along with the provided error
  # message) in the feed view.
  #

  class AuthorizationError < StandardError

    # @return [String, nil] machine-readable error identifier
    attr_reader :error_type

    # @param message [String] human-readable error message
    # @param error_type [String] machine-readable error code
    #
    def initialize(message = "Authentication required", error_type = "AuthenticationRequired")
      super(message)
      @error_type = error_type
    end
  end

  #
  # Raised when some required configuration is missing or invalid.
  #

  class ConfigurationError < StandardError
  end

  #
  # Raised during request processing if some of the parameters are invalid. The error is turned
  # into a "400 Bad Request" response send to the AppView.
  #

  class InvalidRequestError < StandardError

    # @return [String, nil] machine-readable error identifier
    attr_reader :error_type

    # @param message [String] human-readable error message
    # @param error_type [String] machine-readable error code
    #
    def initialize(message, error_type = "InvalidRequest")
      super(message)
      @error_type = error_type
    end
  end

  #
  # Raised during request processing if the response returned by the user's class from the
  # {FeedHandler#get_posts} method doesn't fully match the expected format. The error is turned
  # into a "500 Internal Server Error" response returned to the AppView.
  #

  class InvalidResponseError < StandardError
  end

  #
  # Raised during request processing if the user's provided class does not have expected API.
  #

  class InvalidFeedClassError < StandardError
  end

  #
  # Raised during request processing if the `:feed` parameter points to a feed generator URI
  # which is not on the list of feeds configured in the app.
  #

  class UnsupportedAlgorithmError < StandardError
  end
end
