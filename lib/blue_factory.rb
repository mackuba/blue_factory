require 'json'
require 'sinatra/base'

require_relative "blue_factory/errors"
require_relative "blue_factory/version"

class BlueFactory < Sinatra::Base
  FEED_GENERATOR_TYPE = 'app.bsky.feed.generator'

  set :hostname, nil
  set :publisher_did, nil

  configure do
    disable :static
    enable :quiet
    set :default_content_type, 'application/json'
    settings.add_charset << 'application/json'

    @feeds = {}
  end

  configure :development do
    enable :logging
    disable :quiet
  end

  class << self
    def add_feed(key, feed_class)
      @feeds[key.to_s] = feed_class
    end

    def all_feeds
      @feeds.keys
    end

    def get_feed(key)
      @feeds[key.to_s]
    end

    def service_did
      'did:web:' + settings.hostname
    end
  end

  helpers do
    def feed_uri(key)
      'at://' + settings.publisher_did + '/' + FEED_GENERATOR_TYPE + '/' + key
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
    feed = settings.get_feed(feed_key)

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
      did: settings.service_did,
      feeds: settings.all_feeds.map { |f| { uri: feed_uri(f) }}
    })
  end

  get '/.well-known/did.json' do
    return json({
      '@context': ['https://www.w3.org/ns/did/v1'],
      id: settings.service_did,
      service: [
        {
          id: '#bsky_fg',
          type: 'BskyFeedGenerator',
          serviceEndpoint: 'https://' + settings.hostname
        }
      ]
    })
  end
end
