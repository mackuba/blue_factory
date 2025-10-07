require_relative 'errors'

class OutputGenerator
  def validate_response(response)
    cursor = response[:cursor]
    raise InvalidResponseError, ":cursor key is missing" unless response.has_key?(:cursor)
    raise InvalidResponseError, ":cursor should be a string or nil" unless cursor.nil? || cursor.is_a?(String)

    posts = response[:posts]
    raise InvalidResponseError, ":posts key is missing" unless response.has_key?(:posts)
    raise InvalidResponseError, ":posts should be an array" unless posts.is_a?(Array)
    # raise InvalidResponseError, ":posts should be an array of strings" unless posts.all? { |x| x.is_a?(String) }
    #
    # if bad_uri = posts.detect { |x| x !~ AT_URI_REGEXP }
    #   raise InvalidResponseError, "Invalid post URI: #{bad_uri}"
    # end
  end

  def generate(response)
    output = {}

    output[:feed] = response[:posts].map { |x| process_post_object(x) }
    output[:cursor] = response[:cursor] if response[:cursor]
    output[:reqId] = response[:req_id] if response[:req_id]

    output
  end

  def process_post_object(object)
    if object.is_a?(String)
      return { post: object }
    end

    post = {}

    if object[:post]
      post[:post] = object[:post]
    else
      raise InvalidResponseError, "post hash is missing a :post key"
    end

    if object[:reason]
      post[:reason] = process_post_reason(object[:reason])
    end

    if object[:context]
      post[:feedContext] = object[:context]
    end

    post
  end

  def process_post_reason(reason)
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
      raise InvalidResponseError, "invalid post reason: #{reason.inspect}"
    end
  end
end
