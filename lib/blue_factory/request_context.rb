require_relative 'user_info'

module BlueFactory
  ##
  # Wraps a Sinatra request with convenience helpers.
  class RequestContext
    # @return [Sinatra::Request] underlying request object
    attr_accessor :request

    ##
    # @param request [Sinatra::Request] incoming HTTP request
    def initialize(request)
      @request = request
    end

    ##
    # Request environment hash.
    #
    # @return [Hash] Rack environment
    def env
      @request.env
    end

    ##
    # Parsed user information derived from authorization headers.
    #
    # @return [UserInfo] user info wrapper
    def user
      UserInfo.new(env['HTTP_AUTHORIZATION'])
    end

    ##
    # Indicates whether an authorization header was provided.
    #
    # @return [Boolean] true when authorization exists
    def has_auth?
      env['HTTP_AUTHORIZATION'] != nil
    end
  end
end
