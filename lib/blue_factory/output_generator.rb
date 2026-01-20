require_relative 'errors'

module BlueFactory
  ##
  # Builds the feed skeleton response structure expected by AT Protocol.
  class OutputGenerator
    ##
    # Regular expression for validating post URIs.
    AT_URI_REGEXP = %r(^at://did:(plc:[a-z0-9]+|web:[a-z0-9\-]+(\.[a-z0-9\-]+)+)/app\.bsky\.feed\.post/[a-z0-9]+$)

    ##
    # Generates the serialized feed response payload.
    #
    # @param response [Hash] feed response data from the feed class
    # @return [Hash] validated response in the AT Protocol format
    # @raise [InvalidResponseError] when the response is missing required keys
    def generate(response)
      output = {}

      raise InvalidResponseError, ":posts key is missing" unless response.has_key?(:posts)
      raise InvalidResponseError, ":posts should be an array" unless response[:posts].is_a?(Array)

      output[:feed] = response[:posts].map { |x| process_post_element(x) }

      if cursor = response[:cursor]
        output[:cursor] = cursor.to_s
      end

      if req_id = response[:req_id]
        output[:reqId] = req_id.to_s
      end

      output
    end

    ##
    # Normalizes a feed entry as either a post string or a hash.
    #
    # @param object [String, Hash] feed entry payload
    # @return [Hash] normalized post entry
    # @raise [InvalidResponseError] if the entry type is invalid
    def process_post_element(object)
      if object.is_a?(String)
        validate_uri(object)
        { post: object }
      elsif object.is_a?(Hash)
        process_post_hash(object)
      else
        raise InvalidResponseError, "Invalid post entry, expected string or hash: #{object.inspect}"
      end
    end

    ##
    # Converts a post hash to the expected skeleton shape.
    #
    # @param object [Hash] hash including :post and optional metadata
    # @return [Hash] normalized post hash
    # @raise [InvalidResponseError] if the post hash is missing required keys
    def process_post_hash(object)
      post = {}

      if object[:post]
        validate_uri(object[:post])
        post[:post] = object[:post]
      else
        raise InvalidResponseError, "Post hash is missing a :post key"
      end

      if object[:reason]
        post[:reason] = process_post_reason(object[:reason])
      end

      if object[:context]
        post[:feedContext] = object[:context].to_s
      end

      post
    end

    ##
    # Builds the reason payload for a post entry.
    #
    # @param reason [Hash] reason metadata
    # @return [Hash] skeleton reason payload
    # @raise [InvalidResponseError] if the reason data is invalid
    def process_post_reason(reason)
      raise InvalidResponseError, "Invalid post reason: #{reason.inspect}" unless reason.is_a?(Hash)

      if reason[:repost]
        {
          "$type" => "app.bsky.feed.defs#skeletonReasonRepost",
          "repost" => reason[:repost]
        }
      elsif reason[:pin]
        {
          "$type" => "app.bsky.feed.defs#skeletonReasonPin"
        }
      else
        raise InvalidResponseError, "Invalid post reason: #{reason.inspect}"
      end
    end

    ##
    # Validates that a URI is in the expected AT Protocol format.
    #
    # @param uri [String] post URI
    # @return [void]
    # @raise [InvalidResponseError] if the URI is invalid
    def validate_uri(uri)
      if !uri.is_a?(String)
        raise InvalidResponseError, "Post URI should be a string: #{uri.inspect}"
      elsif uri !~ AT_URI_REGEXP
        raise InvalidResponseError, "Invalid post URI: #{uri.inspect}"
      end
    end
  end
end
