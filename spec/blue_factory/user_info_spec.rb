# frozen_string_literal: true

require "spec_helper"

describe BlueFactory::UserInfo do
  it "should return nil when the header is missing" do
    info = BlueFactory::UserInfo.new(nil)

    info.token.should be nil
  end

  it "should return nil when the header is blank" do
    info = BlueFactory::UserInfo.new(" ")

    info.token.should be nil
  end

  it "should raise when the header is not a bearer token" do
    info = BlueFactory::UserInfo.new("Basic abc")

    expect { info.token }.to raise_error(
      BlueFactory::AuthorizationError,
      /Unsupported authorization method/
    )
  end

  it "should extract the bearer token" do
    info = BlueFactory::UserInfo.new("Bearer abc.def.ghi")

    info.token.should == "abc.def.ghi"
  end

  it "should return nil for raw_did when no token is present" do
    info = BlueFactory::UserInfo.new(nil)

    info.raw_did.should be nil
  end

  it "should decode the raw DID from the token payload" do
    payload = Base64.strict_encode64({ iss: "did:plc:abc123" }.to_json)
    token = "header.#{payload}.signature"
    info = BlueFactory::UserInfo.new("Bearer #{token}")

    info.raw_did.should == "did:plc:abc123"
  end

  it "should raise for invalid JWT format" do
    info = BlueFactory::UserInfo.new("Bearer bad.token")

    expect { info.raw_did }.to raise_error(BlueFactory::AuthorizationError) do |error|
      error.message.should == "Invalid JWT format"
      error.error_type.should == "BadJwt"
    end
  end
end
