require 'spec_helper'
require 'json'

describe BlueFactory::Server do
  let(:hostname) { 'feeds.example.com' }
  let(:publisher_did) { 'did:plc:ewvi7nxzyoun6zhxrhs64oiz' }

  before do
    BlueFactory.instance_variable_set('@feeds', {})
    BlueFactory.interactions_handler = nil
    BlueFactory::Server.class_variable_set(:@@config_checked, false)

    BlueFactory.set :hostname, hostname
    BlueFactory.set :publisher_did, publisher_did
  end

  def json_body
    JSON.parse(last_response.body)
  end

  describe 'configuration verification' do
    it 'raises ConfigurationError when hostname is nil' do
      BlueFactory.set :hostname, nil
      BlueFactory::Server.class_variable_set(:@@config_checked, false)

      expect { get '/xrpc/app.bsky.feed.describeFeedGenerator' }
        .to raise_error(BlueFactory::ConfigurationError, /hostname/)
    end

    it 'raises ConfigurationError when publisher_did is nil' do
      BlueFactory.set :publisher_did, nil
      BlueFactory::Server.class_variable_set(:@@config_checked, false)

      expect { get '/xrpc/app.bsky.feed.describeFeedGenerator' }
        .to raise_error(BlueFactory::ConfigurationError, /publisher_did/)
    end
  end

  describe 'GET /xrpc/app.bsky.feed.getFeedSkeleton' do
    let(:feed_key) { 'alpha' }
    let(:feed_uri) { "at://#{publisher_did}/#{BlueFactory::FEED_GENERATOR_TYPE}/#{feed_key}" }
    let(:valid_post_uri) { 'at://did:plc:abc123def456/app.bsky.feed.post/abc123' }

    it 'returns a valid skeleton response for a one-argument get_posts' do
      handler = mock('one_arg_handler')
      handler.expects(:call).with do |args|
        args[:feed] == feed_uri &&
          args[:cursor] == 'next' &&
          args[:limit] == BlueFactory::MAX_LIMIT
      end.returns({ posts: [valid_post_uri], cursor: :cursor_token, req_id: :req_token })

      feed = Class.new do
        def initialize(handler)
          @handler = handler
        end

        def get_posts(args)
          @handler.call(args)
        end
      end.new(handler)

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: 'next', limit: 999

      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to include('application/json')
      expect(json_body).to eq(
        'feed' => [{ 'post' => valid_post_uri }],
        'cursor' => 'cursor_token',
        'reqId' => 'req_token'
      )
    end

    it 'passes a RequestContext to a two-argument get_posts' do
      handler = mock('two_arg_handler')
      handler.expects(:call).with do |args, context|
        args[:feed] == feed_uri && context.is_a?(BlueFactory::RequestContext)
      end.returns({ posts: [valid_post_uri] })

      feed = Class.new do
        def initialize(handler)
          @handler = handler
        end

        def get_posts(args, context)
          @handler.call(args, context)
        end
      end.new(handler)

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      expect(last_response.status).to eq(200)
      expect(json_body['feed']).to eq([{ 'post' => valid_post_uri }])
    end

    it 'raises InvalidFeedClassError when get_posts arity is unsupported' do
      feed = Class.new do
        def get_posts; end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      expect { get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri }
        .to raise_error(BlueFactory::InvalidFeedClassError, /arity 0/)
    end

    it 'returns InvalidRequest when feed is missing' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton'

      expect(last_response.status).to eq(400)
      expect(json_body).to include(
        'error' => 'InvalidRequest',
        'message' => 'Error: Params must have the property "feed"'
      )
    end

    it 'returns InvalidRequest when feed is not a valid at-uri' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: 'not-an-at-uri'

      expect(last_response.status).to eq(400)
      expect(json_body).to include(
        'error' => 'InvalidRequest',
        'message' => 'Error: feed must be a valid at-uri'
      )
    end

    it 'returns UnsupportedAlgorithm when the feed is not registered' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      expect(last_response.status).to eq(400)
      expect(json_body).to include(
        'error' => 'UnsupportedAlgorithm',
        'message' => 'Unsupported algorithm'
      )
    end

    it 'returns UnsupportedAlgorithm when the URI does not match the registered feed' do
      feed = Class.new do
        def get_posts(args); end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      mismatched_uri = "at://did:plc:someoneelse/#{BlueFactory::FEED_GENERATOR_TYPE}/#{feed_key}"
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: mismatched_uri

      expect(last_response.status).to eq(400)
      expect(json_body).to include(
        'error' => 'UnsupportedAlgorithm',
        'message' => 'Unsupported algorithm'
      )
    end

    it 'returns Unauthorized when the feed raises AuthorizationError' do
      feed = Class.new do
        def get_posts(_args, context)
          context.user.raw_did
          { posts: [] }
        end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      header 'Authorization', 'Basic not-a-bearer-token'
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      expect(last_response.status).to eq(401)
      expect(json_body).to include(
        'error' => 'AuthenticationRequired',
        'message' => 'Unsupported authorization method'
      )
    end

    it 'returns a generic InvalidResponse error in non-development environments' do
      handler = mock('invalid_response_handler')
      handler.stubs(:call).returns({ posts: 'not-an-array' })

      feed = Class.new do
        def initialize(handler)
          @handler = handler
        end

        def get_posts(args)
          @handler.call(args)
        end
      end.new(handler)
      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      expect(last_response.status).to eq(500)
      expect(json_body).to include(
        'error' => 'InvalidResponse',
        'message' => 'Feed response was invalid'
      )
    end
  end

  describe 'GET /xrpc/app.bsky.feed.describeFeedGenerator' do
    it 'returns the service did and configured feed uris' do
      feed = Class.new do
        def get_posts(args); end
      end.new

      BlueFactory.add_feed('alpha', feed)
      BlueFactory.add_feed('beta', feed)

      get '/xrpc/app.bsky.feed.describeFeedGenerator'

      expect(last_response.status).to eq(200)
      expect(json_body).to eq(
        'did' => "did:web:#{hostname}",
        'feeds' => [
          { 'uri' => "at://#{publisher_did}/#{BlueFactory::FEED_GENERATOR_TYPE}/alpha" },
          { 'uri' => "at://#{publisher_did}/#{BlueFactory::FEED_GENERATOR_TYPE}/beta" }
        ]
      )
    end
  end

  describe 'GET /.well-known/did.json' do
    it 'returns the expected DID document' do
      get '/.well-known/did.json'

      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to include('application/json')
      expect(json_body).to eq(
        '@context' => ['https://www.w3.org/ns/did/v1'],
        'id' => "did:web:#{hostname}",
        'service' => [
          {
            'id' => '#bsky_fg',
            'type' => 'BskyFeedGenerator',
            'serviceEndpoint' => "https://#{hostname}"
          }
        ]
      )
    end
  end

  describe 'POST /xrpc/app.bsky.feed.sendInteractions' do
    let(:interaction_event) { 'app.bsky.feed.defs#interactionSeen' }
    let(:interaction_item) { 'at://did:plc:abc123def456/app.bsky.feed.post/abc123' }

    it 'calls the configured interactions handler' do
      received_interactions = nil
      received_context = nil

      BlueFactory.on_interactions do |interactions, context|
        received_interactions = interactions
        received_context = context
      end

      payload = {
        interactions: [
          {
            event: interaction_event,
            item: interaction_item,
            feedContext: 'ctx',
            reqId: 'req-1'
          }
        ]
      }

      post '/xrpc/app.bsky.feed.sendInteractions', JSON.generate(payload), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(received_context).to be_a(BlueFactory::RequestContext)
      expect(received_interactions.map(&:type)).to eq([:seen])
      expect(received_interactions.map(&:item)).to eq([interaction_item])
      expect(received_interactions.map(&:context)).to eq(['ctx'])
      expect(received_interactions.map(&:req_id)).to eq(['req-1'])
    end

    it 'returns MethodNotImplemented when no handler is configured' do
      post '/xrpc/app.bsky.feed.sendInteractions', JSON.generate(interactions: []), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(501)
      expect(json_body).to include(
        'error' => 'MethodNotImplemented',
        'message' => 'Method Not Implemented'
      )
    end
  end
end
