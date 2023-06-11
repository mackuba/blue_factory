require 'json'
require 'sinatra/base'

require_relative 'configuration'
require_relative 'errors'

module BlueFactory
  class Server < Sinatra::Base
    configure do
      disable :static
      enable :quiet
      set :default_content_type, 'application/json'
      settings.add_charset << 'application/json'
    end

    configure :development do
      enable :logging
      disable :quiet
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
    end

    get '/xrpc/app.bsky.feed.getFeedSkeleton' do
      if params[:feed].to_s.empty?
        return json_error("InvalidRequest", "Error: Params must have the property \"feed\"")
      end

      if params[:feed] !~ %r(^at://[\w\-\.\:]+/[\w\.]+/[\w\.\-]+$)
        return json_error("InvalidRequest", "Error: feed must be a valid at-uri")
      end

      feed_key = params[:feed].split('/').last
      feed = config.get_feed(feed_key)

      if feed.nil? || feed_uri(feed_key) != params[:feed]
        return json_error("UnsupportedAlgorithm", "Unsupported algorithm")
      end

      begin
        response = feed.get_posts(params.slice(:feed, :cursor, :limit))

        return json({
          cursor: response[:cursor],
          feed: response[:posts].map { |s| { post: s }}
        })
      rescue InvalidRequestError => e
        return json_error(e.error_type || "InvalidRequest", e.message)
      end
    end

    get '/xrpc/app.bsky.feed.describeFeedGenerator' do
      return json({
        did: config.service_did,
        feeds: config.all_feeds.map { |f| { uri: feed_uri(f) }}
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
