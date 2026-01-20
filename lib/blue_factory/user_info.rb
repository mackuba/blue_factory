require 'base64'
require 'json'

require_relative 'errors'

module BlueFactory
  ##
  # Parses authorization header information for a user.
  class UserInfo
    ##
    # @param auth_header [String, nil] authorization header value
    def initialize(auth_header)
      @auth = auth_header
    end

    ##
    # Extracts the bearer token from the authorization header.
    #
    # @return [String, nil] bearer token
    # @raise [AuthorizationError] if the auth method is unsupported
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

    ##
    # Decodes the raw DID from the JWT payload.
    #
    # @return [String, nil] DID issuer value
    # @raise [AuthorizationError] when the token format is invalid
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
