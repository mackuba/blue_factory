require_relative 'user_info'

module BlueFactory

  #
  # An object which provides some metadata about the `getFeedSkeleton` request being processed.
  # The context is passed to the `#get_posts` method of the provided feed handler object, if the
  # method is made to accept two parameters.
  #

  class RequestContext

    # Returns the underlying request object.
    #
    # @return [Sinatra::Request]
    #   see {https://www.rubydoc.info/gems/sinatra/Sinatra/Request Sinatra::Request}
    #
    attr_reader :request

    # @param request
    #   ({https://www.rubydoc.info/gems/sinatra/Sinatra/Request Sinatra::Request})
    #   &nbsp;&mdash; the original Sinatra/Rack request object
    #
    def initialize(request)
      @request = request
    end

    #
    # The request environment hash.
    # @return [Hash] Rack environment
    #
    def env
      @request.env
    end

    #
    # Parsed user information derived from the authorization header.
    # @return [UserInfo]
    #
    def user
      UserInfo.new(env['HTTP_AUTHORIZATION'])
    end

    #
    # Indicates if an authorization header was provided at all or not.
    # @return [Boolean] true when the authorization header is non-empty
    #
    def has_auth?
      env['HTTP_AUTHORIZATION'] != nil
    end
  end
end
