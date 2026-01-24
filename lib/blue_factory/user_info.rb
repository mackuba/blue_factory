require 'base64'
require 'json'

require_relative 'errors'

module BlueFactory

  #
  # An object which provides info about the user making the request, based on the
  # included authorization header (if any). Accessed through {RequestContext#user}.
  #

  class UserInfo

    #
    # @param auth_header [String, nil] value of the "Authorization" HTTP header
    #
    def initialize(auth_header)
      @auth = auth_header
    end

    #
    # The bearer token extracted from the authorization header.
    #
    # @return [String, nil]
    # @raise [AuthorizationError] if the header is not a "Bearer" token
    #
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

    #
    # Returns the user's (unverified) DID decoded from the JWT payload of the bearer token.
    #
    # Important: this method does not verify the signature of the token, which means
    # the token can be fairly easily forged to impersonate another user, and this method
    # would not detect that. Do not rely on it for use cases where it's important to be
    # certain of the requesting user's identity.
    #
    # @return [String, nil] user DID decoded from the token
    # @raise [AuthorizationError] when the token format is invalid
    #
    def raw_did
      return nil if token.nil?

      parts = token.split('.')
      raise AuthorizationError.new("Invalid JWT format", "BadJwt") unless parts.length == 3

      begin
        payload = JSON.parse(Base64.decode64(parts[1]))
      rescue StandardError => e
        raise AuthorizationError.new("Invalid JWT format", "BadJwt")
      end

      if did = payload['iss']
        did
      else
        raise AuthorizationError.new("Invalid JWT format", "BadJwt")
      end
    end
  end
end
