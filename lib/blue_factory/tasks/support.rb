require 'json'
require 'net/http'
require 'uri'

module BlueFactory
  module Net
    class ResponseError < StandardError; end

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
