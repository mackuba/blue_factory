require 'spec_helper'

describe BlueFactory::OutputGenerator do
  subject { BlueFactory::OutputGenerator.new }

  let(:post_uri) { 'at://did:plc:abc123/app.bsky.feed.post/def456' }
  let(:second_post_uri) { 'at://did:plc:abc123/app.bsky.feed.post/ghi789' }

  it 'should generate feed output from received get_posts response' do
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

    output = subject.generate(response)

    output.should == {
      feed: [
        {
          :post => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3lwtzoigbp22x",
          :reason => { "$type" => "app.bsky.feed.defs#skeletonReasonPin" }
        },
        { :post => "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f" },
        { :post => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r" },
        {
          :post => "at://did:plc:4adlzwqtkv4dirxjwq4c3tlm/app.bsky.feed.post/3mcvrvtlk2j2t",
          :reason => {
            "$type" => "app.bsky.feed.defs#skeletonReasonRepost",
            "repost" => "at://did:plc:vmt7o7y6titkqzzxav247zrn/app.bsky.feed.repost/3md54l2q7zc2w"
          },
          :feedContext => "17480484288:28"
        },
        { :post => "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h" },
        { :post => "at://did:plc:2zziubqb5v7bdw2ahteej7wr/app.bsky.feed.post/3md4wfrap6t2c" }
      ],
      cursor: "2026-01-24T00:32:27.137Z",
      reqId: "17480484288"
    }
  end

  it 'should not raise an error when cursor or req_id are not set' do
    response = {
      posts: [
        "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f",
        "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
        "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h",
      ]
    }

    output = subject.generate(response)

    output.should == {
      feed: [
        { :post => "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f" },
        { :post => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r" },
        { :post => "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h" },
      ]
    }
  end

  it 'should raise an error when posts field is missing' do
    expect { subject.generate({}) }.to raise_error(BlueFactory::InvalidResponseError)
  end

  it 'should raise an error when posts field is not an array' do
    response = "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f"

    expect { subject.generate(posts: response) }.to raise_error(BlueFactory::InvalidResponseError)
  end

  it 'should convert cursor to a string' do
    response = {
      posts: [
        "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f",
        "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
        "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h",
      ],
      cursor: 123
    }

    output = subject.generate(response)

    output[:cursor].should == '123'
  end

  it 'should convert req_id to a string' do
    response = {
      posts: [
        "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f",
        "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
        "at://did:plc:hpv2yni36g2b4ymwsdg2uwre/app.bsky.feed.post/3md4xjrcmj22h",
      ],
      req_id: 1024
    }

    output = subject.generate(response)

    output[:reqId].should == '1024'
  end

  it 'should convert post context to a string' do
    response = {
      posts: [
        "at://did:plc:rnpkyqnmsw4ipey6eotbdnnf/app.bsky.feed.post/3md4khzlybs2f",
        {
          :post => "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
          :context => 16777216
        }
      ]
    }

    output = subject.generate(response)

    output[:feed][1][:feedContext].should == '16777216'
  end

  it 'should raise when a post string has an invalid URI' do
    bad_posts = [
      'bad uri',
      :test,
      [1, 2, 3],
      { post: 'bad uri' },
      { post: :test },
    ]

    bad_posts.each do |post|
      expect { subject.generate(posts: [post]) }.to raise_error(BlueFactory::InvalidResponseError)
    end
  end

  it 'should raise an error when a post hash is missing :post' do
    response = {
      posts: [
        { reason: { pin: true }}
      ]
    }

    expect { subject.generate(response) }.to raise_error(BlueFactory::InvalidResponseError)
  end

  it 'should raise an error when a post reason is not a hash' do
    response = {
      posts: [
        {
          post: "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
          reason: 'test'
        }
      ]
    }

    expect { subject.generate(response) }.to raise_error(BlueFactory::InvalidResponseError)
  end

  it 'should raise an error when a post reason is not recognized' do
    response = {
      posts: [
        {
          post: "at://did:plc:oio4hkxaop4ao4wz2pp3f4cr/app.bsky.feed.post/3md5h3jg6as2r",
          reason: { :test => true }
        }
      ]
    }

    expect { subject.generate(response) }.to raise_error(BlueFactory::InvalidResponseError)
  end
end
