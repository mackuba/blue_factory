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

  def response
    last_response
  end

  def json
    JSON.parse(response.body)
  end

  class TestFeed0
    def get_posts
      load_posts
    end
  end

  class TestFeed1
    def get_posts(params)
      load_posts(params)
    end
  end

  class TestFeed2
    def get_posts(params, context)
      load_posts(params, context)
    end
  end

  class TestFeed3
    def get_posts(params, context, headers)
      load_posts(params, context, headers)
    end
  end

  describe 'configuration checks' do
    it 'should raise ConfigurationError when hostname is nil' do
      BlueFactory.set :hostname, nil

      expect { get '/xrpc/app.bsky.feed.describeFeedGenerator' }.to raise_error(BlueFactory::ConfigurationError)
    end

    it 'should raise ConfigurationError when publisher_did is nil' do
      BlueFactory.set :publisher_did, nil

      expect { get '/xrpc/app.bsky.feed.describeFeedGenerator' }.to raise_error(BlueFactory::ConfigurationError)
    end
  end

  describe 'GET /xrpc/app.bsky.feed.getFeedSkeleton' do
    let(:feed_key) { 'alpha' }
    let(:feed_uri) { "at://#{publisher_did}/app.bsky.feed.generator/#{feed_key}" }
    let(:valid_post_uri) { 'at://did:plc:abc123def456/app.bsky.feed.post/abc123' }

    it 'should return a valid skeleton response for get_posts with one argument' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri, 'cursor' => 'cursor0', 'limit' => 30 })
        .returns({
          posts: [valid_post_uri],
          cursor: 'cursor1',
          req_id: 'req12'
        })

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: 'cursor0', limit: 30

      response.status.should == 200
      response.headers['Content-Type'].should include('application/json')

      json.should == {
        'feed' => [{ 'post' => valid_post_uri }],
        'cursor' => 'cursor1',
        'reqId' => 'req12'
      }
    end

    it 'should process the response from the expected format' do
      response = {
        posts: [
          {
            :post => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3lwtzoigbp22x",
            :reason => { :pin => true }
          },
          "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f",
          "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
          {
            :post => "at://did:plc:4adlzwqtkv4dirxjwq4c3tlm/app.bsky.feed.post/3mcvrvtlk2j2t",
            :reason => { :repost => "at://did:plc:vmt7o7y6titkqzzxav247zrn/app.bsky.feed.repost/3md54l2q7zc2w" },
            :context => "17480484288:28"
          },
          "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h",
          {
            :post => "at://did:plc:2zziubqb5v7bdw2ahteej7wr/app.bsky.feed.post/3md4wfrap6t2c"
          }
        ],
        cursor: "2026-01-24T00:32:27.137Z",
        req_id: "17480484288"
      }

      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri })
        .returns(response)

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      json.should == {
        'feed' => [
          {
            'post' => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3lwtzoigbp22x",
            'reason' => { "$type" => "app.bsky.feed.defs#skeletonReasonPin" }
          },
          { 'post' => "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f" },
          { 'post' => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r" },
          {
            'post' => "at://did:plc:4adlzwqtkv4dirxjwq4c3tlm/app.bsky.feed.post/3mcvrvtlk2j2t",
            'reason' => {
              "$type" => "app.bsky.feed.defs#skeletonReasonRepost",
              "repost" => "at://did:plc:vmt7o7y6titkqzzxav247zrn/app.bsky.feed.repost/3md54l2q7zc2w"
            },
            'feedContext' => "17480484288:28"
          },
          { 'post' => "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h" },
          { 'post' => "at://did:plc:2zziubqb5v7bdw2ahteej7wr/app.bsky.feed.post/3md4wfrap6t2c" }
        ],
        'cursor' => "2026-01-24T00:32:27.137Z",
        'reqId' => "17480484288"
      }
    end

    it 'should pass the params in an IndifferentHash' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with { |params|
          params.is_a?(Sinatra::IndifferentHash) &&
          params['feed'] == feed_uri &&
          params[:feed] == feed_uri
        }
        .returns({ posts: [valid_post_uri] })

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri
    end

    it 'should pass a RequestContext to a get_posts with two arguments' do
      received_context = nil

      feed = TestFeed2.new
      feed.expects(:load_posts)
        .with { |params, ctx|
          received_context = ctx
          params == { 'feed' => feed_uri, 'cursor' => 'zzz7', 'limit' => 10 } && ctx.is_a?(BlueFactory::RequestContext)
        }
        .returns({ posts: [valid_post_uri] })

      BlueFactory.add_feed(feed_key, feed)

      header 'Authorization', 'Bearer foo'
      header 'User-Agent', 'Minisky/0.5'

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: 'zzz7', limit: 10

      response.status.should == 200
      json['feed'].should == [{ 'post' => valid_post_uri }]

      received_context.request.should be_a(Rack::Request)

      received_context.env.should be_a(Hash)
      received_context.env['HTTP_USER_AGENT'].should == 'Minisky/0.5'

      received_context.has_auth?.should == true
      received_context.user.should be_a(BlueFactory::UserInfo)
      received_context.user.token.should == 'foo'
    end

    it 'should not pass through unexpected params' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri, 'cursor' => 'c5' })
        .returns({ posts: [] })

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: 'c5', include_reposts: true, lang: 'en'
    end

    it 'should make sure limit is not lower than 1' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri, 'limit' => 1 })
        .returns({ posts: [] })
        .times(3)

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, limit: 0
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, limit: '-1'
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, limit: 'lizard'
    end

    it 'should make sure limit is not higher than 100' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri, 'limit' => 100 })
        .returns({ posts: [] })

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, limit: 2000
    end

    it 'should raise InvalidFeedClassError when get_posts arity is different than 1 or 2' do
      feed0 = TestFeed0.new
      feed3 = TestFeed3.new

      BlueFactory.add_feed('feed0', feed0)
      BlueFactory.add_feed('feed3', feed3)

      expect { get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: "at://#{publisher_did}/app.bsky.feed.generator/feed0" }
        .to raise_error(BlueFactory::InvalidFeedClassError)

      expect { get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: "at://#{publisher_did}/app.bsky.feed.generator/feed3" }
        .to raise_error(BlueFactory::InvalidFeedClassError)
    end

    it 'should return an InvalidRequest error response when feed parameter is missing' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton'

      response.status.should == 400
      json.should include('error' => 'InvalidRequest')
    end

    it 'should return an InvalidRequest error response when feed parameter is not a valid AT URI' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: 'linux'

      response.status.should == 400
      json.should include('error' => 'InvalidRequest')
    end

    it 'should return an UnsupportedAlgorithm error response when no such feed is registered' do
      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      response.status.should == 400
      json.should include('error' => 'UnsupportedAlgorithm')
    end

    it 'should return an UnsupportedAlgorithm error response when the URI does not match the registered feed' do
      feed = TestFeed1.new
      feed.expects(:load_posts).never

      BlueFactory.add_feed(feed_key, feed)

      bad_uri = "at://did:plc:someoneelse/app.bsky.feed.generator/#{feed_key}"

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: bad_uri

      response.status.should == 400
      json.should include('error' => 'UnsupportedAlgorithm')
    end

    it 'should return an Unauthorized error response when the feed raises AuthorizationError' do
      feed = TestFeed1.new
      feed.expects(:load_posts).raises(BlueFactory::AuthorizationError, 'You shall not pass')

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri

      response.status.should == 401
      json.should include('error' => 'AuthenticationRequired', 'message' => 'You shall not pass')
    end

    it 'should return an InvalidRequest error response when the feed raises InvalidRequestError' do
      feed = TestFeed1.new
      feed.expects(:load_posts).raises(BlueFactory::InvalidRequestError, 'Bad cursor')

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: '30=c49,hyt=094v,g:7'

      response.status.should == 400
      json.should include('error' => 'InvalidRequest')
    end

    it 'should return an InvalidResponse error when the feed response is invalid' do
      feed = TestFeed1.new
      feed.expects(:load_posts)
        .with({ 'feed' => feed_uri, 'cursor' => 'c20' })
        .returns({ posts: 70 })

      BlueFactory.add_feed(feed_key, feed)

      get '/xrpc/app.bsky.feed.getFeedSkeleton', feed: feed_uri, cursor: 'c20'

      response.status.should == 500
      json.should include('error' => 'InvalidResponse')
    end
  end

  describe 'GET /xrpc/app.bsky.feed.describeFeedGenerator' do
    it 'should return the service did and configured feed uris' do
      BlueFactory.add_feed('cats', TestFeed1.new)
      BlueFactory.add_feed('dogs', TestFeed2.new)

      get '/xrpc/app.bsky.feed.describeFeedGenerator'

      response.status.should == 200
      response.headers['Content-Type'].should include('application/json')

      json.should == {
        'did' => "did:web:#{hostname}",
        'feeds' => [
          { 'uri' => "at://#{publisher_did}/app.bsky.feed.generator/cats" },
          { 'uri' => "at://#{publisher_did}/app.bsky.feed.generator/dogs" }
        ]
      }
    end
  end

  describe 'GET /.well-known/did.json' do
    it 'should return the expected DID document' do
      get '/.well-known/did.json'

      response.status.should == 200
      response.headers['Content-Type'].should include('application/json')

      json.should == {
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
            event: 'app.bsky.feed.defs#requestLess',
            item: 'at://did:plc:vc7f4oafdgxsihk4cry2xpze/app.bsky.feed.post/3mcubye2byc22',
            feedContext: 'ctx1',
            reqId: 'req1'
          },
          {
            event: 'app.bsky.feed.defs#requestMore',
            item: 'at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3mcl43hqoz22a',
            feedContext: 'ctx2',
            reqId: 'req2'
          },
        ]
      }

      header 'Content-Type', 'application/json'
      post '/xrpc/app.bsky.feed.sendInteractions', JSON.generate(payload)

      response.status.should == 200

      received_context.should be_a(BlueFactory::RequestContext)
      received_interactions.should be_an(Array)

      received_interactions.map(&:type).should == [:request_less, :request_more]
      received_interactions.map(&:event).should == ['app.bsky.feed.defs#requestLess', 'app.bsky.feed.defs#requestMore']
      received_interactions.map(&:item).should == [payload[:interactions][0][:item], payload[:interactions][1][:item]]
      received_interactions.map(&:context).should == ['ctx1', 'ctx2']
      received_interactions.map(&:req_id).should == ['req1', 'req2']
    end

    it 'should return a MethodNotImplemented error response when no handler is configured' do
      post '/xrpc/app.bsky.feed.sendInteractions', JSON.generate(interactions: [])

      response.status.should == 501
      json.should include('error' => 'MethodNotImplemented')
    end
  end
end
