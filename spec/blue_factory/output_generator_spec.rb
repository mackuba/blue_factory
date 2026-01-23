# frozen_string_literal: true

require "spec_helper"

describe BlueFactory::OutputGenerator do
  let(:generator) { BlueFactory::OutputGenerator.new }
  let(:post_uri) { "at://did:plc:abc123/app.bsky.feed.post/def456" }
  let(:second_post_uri) { "at://did:plc:abc123/app.bsky.feed.post/ghi789" }

  it "should generate feed output with cursor and reqId" do
    response = {
      posts: [
        post_uri,
        {
          post: second_post_uri,
          reason: { repost: "at://did:plc:abc123/app.bsky.feed.post/xyz000" },
          context: :ctx
        }
      ],
      cursor: 123,
      req_id: :req
    }

    output = generator.generate(response)

    output[:feed].should == [
      { post: post_uri },
      {
        post: second_post_uri,
        reason: {
          "$type" => "app.bsky.feed.defs#skeletonReasonRepost",
          "repost" => "at://did:plc:abc123/app.bsky.feed.post/xyz000"
        },
        feedContext: "ctx"
      }
    ]
    output[:cursor].should == "123"
    output[:reqId].should == "req"
  end

  it "should generate a pin reason for a post hash" do
    response = {
      posts: [
        {
          post: post_uri,
          reason: { pin: true }
        }
      ]
    }

    output = generator.generate(response)

    output[:feed].should == [
      {
        post: post_uri,
        reason: {
          "$type" => "app.bsky.feed.defs#skeletonReasonPin"
        }
      }
    ]
  end

  it "should raise when posts are missing" do
    expect { generator.generate({}) }.to raise_error(
      BlueFactory::InvalidResponseError,
      /:posts key is missing/
    )
  end

  it "should raise when posts are not an array" do
    expect { generator.generate(posts: post_uri) }.to raise_error(
      BlueFactory::InvalidResponseError,
      /:posts should be an array/
    )
  end

  it "should raise when a post string has an invalid URI" do
    expect { generator.generate(posts: ["bad-uri"]) }.to raise_error(
      BlueFactory::InvalidResponseError,
      /Invalid post URI/
    )
  end

  it "should raise when a post hash is missing :post" do
    expect { generator.generate(posts: [{ reason: { pin: true } }]) }.to raise_error(
      BlueFactory::InvalidResponseError,
      /missing a :post key/
    )
  end

  it "should raise when a post reason is invalid" do
    expect { generator.generate(posts: [{ post: post_uri, reason: :bad }]) }.to raise_error(
      BlueFactory::InvalidResponseError,
      /Invalid post reason/
    )
  end
end
