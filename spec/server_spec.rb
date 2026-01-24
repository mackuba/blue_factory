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
    it 'should raise ConfigurationError when hostname is nil' do
      BlueFactory.set :hostname, nil
      BlueFactory::Server.class_variable_set(:@@config_checked, false)

      expect { get '/xrpc/app.bsky.feed.describeFeedGenerator' }
        .to raise_error(BlueFactory::ConfigurationError, /hostname/)
    end

    it 'should raise ConfigurationError when publisher_did is nil' do
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

    it 'should return a valid skeleton response for a one-argument get_posts' do
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

      last_response.status.should == 200
      last_response.headers['Content-Type'].should include('application/json')
      json_body.should == {
        'feed' => [{ 'post' => valid_post_uri }],
        'cursor' => 'cursor_token',
        'reqId' => 'req_token'
      }
    end

    it 'should pass a RequestContext to a two-argument get_posts' do
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

      last_response.status.should == 200
      json_body['feed'].should == [{ 'post' => valid_post_uri }]
    end

    it 'should raise InvalidFeedClassError when get_posts arity is unsupported' do
      feed = Class.new do
        def get_posts; end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      expect { get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri }
        .to raise_error(BlueFactory::InvalidFeedClassError, /arity 0/)
    end

    it 'should return InvalidRequest when feed is missing' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton'

      last_response.status.should == 400
      json_body.should include(
        'error' => 'InvalidRequest',
        'message' => 'Error: Params must have the property "feed"'
      )
    end

    it 'should return InvalidRequest when feed is not a valid at-uri' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: 'not-an-at-uri'

      last_response.status.should == 400
      json_body.should include(
        'error' => 'InvalidRequest',
        'message' => 'Error: feed must be a valid at-uri'
      )
    end

    it 'should return UnsupportedAlgorithm when the feed is not registered' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      last_response.status.should == 400
      json_body.should include(
        'error' => 'UnsupportedAlgorithm',
        'message' => 'Unsupported algorithm'
      )
    end

    it 'should return UnsupportedAlgorithm when the URI does not match the registered feed' do
      feed = Class.new do
        def get_posts(args); end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      mismatched_uri = "at://did:plc:someoneelse/#{BlueFactory::FEED_GENERATOR_TYPE}/#{feed_key}"
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: mismatched_uri

      last_response.status.should == 400
      json_body.should include(
        'error' => 'UnsupportedAlgorithm',
        'message' => 'Unsupported algorithm'
      )
    end

    it 'should return Unauthorized when the feed raises AuthorizationError' do
      feed = Class.new do
        def get_posts(_args, context)
          context.user.raw_did
          { posts: [] }
        end
      end.new

      BlueFactory.add_feed(feed_key, feed)

      header 'Authorization', 'Basic not-a-bearer-token'
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      last_response.status.should == 401
      json_body.should include(
        'error' => 'AuthenticationRequired',
        'message' => 'Unsupported authorization method'
      )
    end

    it 'should return a generic InvalidResponse error in non-development environments' do
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

      last_response.status.should == 500
      json_body.should include(
        'error' => 'InvalidResponse',
        'message' => 'Feed response was invalid'
      )
    end
  end

  describe 'GET /xrpc/app.bsky.feed.describeFeedGenerator' do
    it 'should return the service did and configured feed uris' do
      feed = Class.new do
        def get_posts(args); end
      end.new

      BlueFactory.add_feed('alpha', feed)
      BlueFactory.add_feed('beta', feed)

      get '/xrpc/app.bsky.feed.describeFeedGenerator'

      last_response.status.should == 200
      json_body.should == {
        'did' => "did:web:#{hostname}",
        'feeds' => [
          { 'uri' => "at://#{publisher_did}/#{BlueFactory::FEED_GENERATOR_TYPE}/alpha" },
          { 'uri' => "at://#{publisher_did}/#{BlueFactory::FEED_GENERATOR_TYPE}/beta" }
        ]
      }
    end
  end

  describe 'GET /.well-known/did.json' do
    it 'should return the expected DID document' do
      get '/.well-known/did.json'

      last_response.status.should == 200
      last_response.headers['Content-Type'].should include('application/json')
      json_body.should == {
        '@context' => ['https://www.w3.org/ns/did/v1'],
        'id' => "did:web:#{hostname}",
        'service' => [
          {
            'id' => '#bsky_fg',
            'type' => 'BskyFeedGenerator',
            'serviceEndpoint' => "https://#{hostname}"
          }
        ]
      }
    end
  end

  describe 'POST /xrpc/app.bsky.feed.sendInteractions' do
    let(:interaction_event) { 'app.bsky.feed.defs#interactionSeen' }
    let(:interaction_item) { 'at://did:plc:abc123def456/app.bsky.feed.post/abc123' }

    it 'should call the configured interactions handler' do
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

      last_response.status.should == 200
      received_context.should be_a(BlueFactory::RequestContext)
      received_interactions.map(&:type).should == [:seen]
      received_interactions.map(&:item).should == [interaction_item]
      received_interactions.map(&:context).should == ['ctx']
      received_interactions.map(&:req_id).should == ['req-1']
    end

    it 'should return MethodNotImplemented when no handler is configured' do
      post '/xrpc/app.bsky.feed.sendInteractions', JSON.generate(interactions: []), 'CONTENT_TYPE' => 'application/json'

      last_response.status.should == 501
      json_body.should include(
        'error' => 'MethodNotImplemented',
        'message' => 'Method Not Implemented'
      )
    end
  end
end
