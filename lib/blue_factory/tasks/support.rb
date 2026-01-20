require 'json'
require 'net/http'
require 'uri'

module BlueFactory
  ##
  # Convenience HTTP helpers for rake tasks.
  module Net
    ##
    # Raised when an HTTP response status is non-success.
    class ResponseError < StandardError; end

    ##
    # Executes a GET request against a feed generator endpoint.
    #
    # @param server [String] base server URL
    # @param method [String, nil] optional XRPC method name
    # @param params [Hash, nil] optional query parameters
    # @param auth [String, nil] bearer token
    # @return [Hash] parsed JSON response
    # @raise [ResponseError] if the response status is not 2xx
    def self.get_request(server, method = nil, params = nil, auth: nil)
      headers = {}
      headers['Authorization'] = "Bearer #{auth}" if auth

      url = method ? URI("#{server}/xrpc/#{method}") : URI(server)

      if params && !params.empty?
        url.query = URI.encode_www_form(params)
      end

      response = ::Net::HTTP.get_response(url, headers)
      raise ResponseError, "Invalid response: #{response.code} #{response.body}" if response.code.to_i / 100 != 2

      JSON.parse(response.body)
    end

    ##
    # Executes a POST request against a feed generator endpoint.
    #
    # @param server [String] base server URL
    # @param method [String] XRPC method name
    # @param data [Hash, String] request body
    # @param auth [String, nil] bearer token
    # @param content_type [String] HTTP content type
    # @return [Hash] parsed JSON response
    # @raise [ResponseError] if the response status is not 2xx
    def self.post_request(server, method, data, auth: nil, content_type: "application/json")
      headers = {}
      headers['Content-Type'] = content_type
      headers['Authorization'] = "Bearer #{auth}" if auth

      body = data.is_a?(String) ? data : data.to_json

      response = ::Net::HTTP.post(URI("#{server}/xrpc/#{method}"), body, headers)
      raise ResponseError, "Invalid response: #{response.code} #{response.body}" if response.code.to_i / 100 != 2

      JSON.parse(response.body)
    end
  end
end
