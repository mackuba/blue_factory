require_relative 'errors'

class OutputGenerator
  AT_URI_REGEXP = %r(^at://did:plc:[a-z0-9]+/app\.bsky\.feed\.post/[a-z0-9]+$)

  def generate(response)
    output = {}

    raise InvalidResponseError, ":posts key is missing" unless response.has_key?(:posts)
    raise InvalidResponseError, ":posts should be an array" unless response[:posts].is_a?(Array)

    output[:feed] = response[:posts].map { |x| process_post_element(x) }

    if cursor = response[:cursor]
      raise InvalidResponseError, ":cursor should be a string or nil" unless cursor.is_a?(String)
      output[:cursor] = cursor
    end

    if req_id = response[:req_id]
      raise InvalidResponseError, ":req_id should be a string or nil" unless req_id.is_a?(String)
      output[:reqId] = req_id
    end

    output
  end

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
      raise InvalidResponseError, ":context should be a string or nil" unless object[:context].is_a?(String)
      post[:feedContext] = object[:context]
    end

    post
  end

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

  def validate_uri(uri)
    if !uri.is_a?(String)
      raise InvalidResponseError, "Post URI should be a string: #{uri.inspect}"
    elsif uri !~ AT_URI_REGEXP
      raise InvalidResponseError, "Invalid post URI: #{uri.inspect}"
    end
  end
end
