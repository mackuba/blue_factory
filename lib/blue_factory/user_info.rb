require 'base64'
require 'json'

require_relative 'errors'

module BlueFactory
  class UserInfo
    def initialize(auth_header)
      @auth = auth_header
    end

    def token
      @token ||= begin
        if @auth.nil? || @auth.strip.empty?
          nil
        elsif !@auth.start_with?('Bearer ')
          raise AuthorizationError, "Unsupported authorization method"
        else
          @auth.gsub(/^Bearer /, '')
        end
      end
    end

    def raw_did
      return nil if token.nil?

      parts = token.split('.')
      raise AuthorizationError.new("Invalid JWT format", "BadJwt") unless parts.length == 3

      begin
        payload = JSON.parse(Base64.decode64(parts[1]))
        payload['iss']
      rescue StandardError => e
        raise AuthorizationError.new("Invalid JWT format", "BadJwt")
      end
    end
  end
end
