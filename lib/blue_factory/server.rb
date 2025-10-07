require 'json'
require 'sinatra/base'

require_relative 'configuration'
require_relative 'errors'
require_relative 'interaction'
require_relative 'output_generator'
require_relative 'request_context'

module BlueFactory
  class Server < Sinatra::Base
    configure do
      disable :static
      enable :quiet
      enable :logging
      settings.add_charset << 'application/json'
    end

    helpers do
      def config
        BlueFactory
      end

      def feed_uri(key)
        'at://' + config.publisher_did + '/' + FEED_GENERATOR_TYPE + '/' + key
      end

      def json_response(data)
        content_type :json
        JSON.generate(data)
      end

      alias json json_response

      def json_error(name, message, status: 400)
        content_type :json
        [status, JSON.generate({ error: name, message: message })]
      end

      def get_feed(feed_uri)
        if feed_uri.to_s.empty?
          raise InvalidRequestError, "Error: Params must have the property \"feed\""
        end

        if feed_uri !~ %r(^at://[\w\-\.\:]+/[\w\.]+/[\w\.\-]+$)
          raise InvalidRequestError, "Error: feed must be a valid at-uri"
        end

        feed_key = feed_uri.split('/').last
        feed = config.get_feed(feed_key)

        if feed.nil? || feed_uri(feed_key) != feed_uri
          raise UnsupportedAlgorithmError, "Unsupported algorithm"
        end

        feed
      end
    end

    get '/xrpc/app.bsky.feed.getFeedSkeleton' do
      begin
        feed = get_feed(params[:feed])
        get_posts = feed.method(:get_posts)
        args = params.slice(:feed, :cursor, :limit)

        if config.enable_unsafe_auth
          context = RequestContext.new(request)
          response = feed.get_posts(args, context.user.raw_did)
        elsif get_posts.arity == 1
          response = feed.get_posts(args)
        elsif get_posts.arity == 2
          context = RequestContext.new(request)
          response = feed.get_posts(args, context)
        else
          raise InvalidFeedClassError, "get_posts method has invalid API (arity #{get_posts.arity})"
        end

        json = OutputGenerator.new.generate(response)
        return json_response(json)
      rescue InvalidRequestError => e
        return json_error(e.error_type || "InvalidRequest", e.message)
      rescue AuthorizationError => e
        return json_error(e.error_type || "AuthenticationRequired", e.message, status: 401)
      rescue UnsupportedAlgorithmError => e
        return json_error("UnsupportedAlgorithm", e.message)
      rescue InvalidResponseError => e
        if settings.development?
          return json_error("InvalidResponse", e.message, status: 500)
        else
          request.logger&.<< "#{e.class}: #{e.message}\n"
          return json_error("InvalidResponse", "Feed response was invalid", status: 500)
        end
      end
    end

    get '/xrpc/app.bsky.feed.describeFeedGenerator' do
      json_response({
        did: config.service_did,
        feeds: config.feed_keys.map { |f| { uri: feed_uri(f) }}
      })
    end

    get '/.well-known/did.json' do
      json_response({
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

    post '/xrpc/app.bsky.feed.sendInteractions' do
      if config.interactions_handler
        json = JSON.parse(request.body.read)
        interactions = json['interactions'].map { |x| Interaction.new(x) }
        context = RequestContext.new(request)

        config.interactions_handler.call(interactions, context)
        status 200
      else
        json_error('MethodNotImplemented', 'Method Not Implemented', status: 501)
      end
    end
  end
end
