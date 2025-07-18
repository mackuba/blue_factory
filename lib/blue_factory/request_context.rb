require_relative 'user_info'

module BlueFactory
  class RequestContext
    attr_accessor :request

    def initialize(request)
      @request = request
    end

    def env
      @request.env
    end

    def user
      UserInfo.new(env['HTTP_AUTHORIZATION'])
    end

    def has_auth?
      env['HTTP_AUTHORIZATION'] != nil
    end
  end
end
