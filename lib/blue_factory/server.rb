require 'json'
require 'sinatra/base'

require_relative 'configuration'
require_relative 'errors'

module BlueFactory
  class Server < Sinatra::Base
    AT_URI_REGEXP = %r(^at://did:plc:[a-z0-9]+/app\.bsky\.feed\.post/[a-z0-9]+$)

    configure do
      disable :static
      enable :quiet
      enable :logging
      set :default_content_type, 'application/json'
      settings.add_charset << 'application/json'
    end

    helpers do
      def config
        BlueFactory
      end

      def feed_uri(key)
        'at://' + config.publisher_did + '/' + FEED_GENERATOR_TYPE + '/' + key
      end

      def json(data)
        JSON.generate(data)
      end

      def json_error(name, message, status: 400)
        [status, JSON.generate({ error: name, message: message })]
      end

      def get_feed
        if params[:feed].to_s.empty?
          raise InvalidResponseError, "Error: Params must have the property \"feed\""
        end

        if params[:feed] !~ %r(^at://[\w\-\.\:]+/[\w\.]+/[\w\.\-]+$)
          raise InvalidResponseError, "Error: feed must be a valid at-uri"
        end

        feed_key = params[:feed].split('/').last
        feed = config.get_feed(feed_key)

        if feed.nil? || feed_uri(feed_key) != params[:feed]
          raise UnsupportedAlgorithmError, "Unsupported algorithm"
        end

        feed
      end

      def validate_response(response)
        cursor = response[:cursor]
        raise InvalidResponseError, ":cursor key is missing" unless response.has_key?(:cursor)
        raise InvalidResponseError, ":cursor should be a string or nil" unless cursor.nil? || cursor.is_a?(String)

        posts = response[:posts]
        raise InvalidResponseError, ":posts key is missing" unless response.has_key?(:posts)
        raise InvalidResponseError, ":posts should be an array of strings" unless posts.is_a?(Array)
        raise InvalidResponseError, ":posts should be an array of strings" unless posts.all? { |x| x.is_a?(String) }

        if bad_uri = posts.detect { |x| x !~ AT_URI_REGEXP }
          raise InvalidResponseError, "Invalid post URI: #{bad_uri}"
        end
      end
    end

    get '/xrpc/app.bsky.feed.getFeedSkeleton' do
      begin
        feed = get_feed
        response = feed.get_posts(params.slice(:feed, :cursor, :limit))
        validate_response(response) if config.validate_responses

        output = {}
        output[:feed] = response[:posts].map { |s| { post: s }}
        output[:cursor] = response[:cursor] if response[:cursor]

        return json(output)
      rescue InvalidRequestError => e
        return json_error(e.error_type || "InvalidRequest", e.message)
      rescue UnsupportedAlgorithmError => e
        return json_error("UnsupportedAlgorithm", e.message)
      rescue InvalidResponseError => e
        return json_error("InvalidResponse", e.message)
      end
    end

    get '/xrpc/app.bsky.feed.describeFeedGenerator' do
      return json({
        did: config.service_did,
        feeds: config.feed_keys.map { |f| { uri: feed_uri(f) }}
      })
    end

    get '/.well-known/did.json' do
      return json({
        '@context': ['https://www.w3.org/ns/did/v1'],
        id: config.service_did,
        service: [
          {
            id: '#bsky_fg',
            type: 'BskyFeedGenerator',
            serviceEndpoint: 'https://' + config.hostname
          }
        ]
      })
    end
  end
end
