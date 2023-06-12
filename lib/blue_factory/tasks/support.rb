require 'json'
require 'net/http'

module BlueFactory
  module Net
    class ResponseError < StandardError; end

    def self.post_request(server, method, data, auth: nil, content_type: "application/json")
      headers = {}
      headers['Content-Type'] = content_type
      headers['Authorization'] = "Bearer #{auth}" if auth

      body = data.is_a?(String) ? data : data.to_json

      puts body unless data.is_a?(String)

      response = ::Net::HTTP.post(URI("#{server}/xrpc/#{method}"), body, headers)
      raise ResponseError, "Invalid response: #{response.code} #{response.body}" if response.code.to_i / 100 != 2

      JSON.parse(response.body)
    end
  end
end
