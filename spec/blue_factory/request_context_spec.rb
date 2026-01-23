# frozen_string_literal: true

require "spec_helper"

describe BlueFactory::RequestContext do
  it "should expose the request and environment" do
    request = double("request", env: { "HTTP_AUTHORIZATION" => "Bearer token-1" })

    context = BlueFactory::RequestContext.new(request)

    context.request.should == request
    context.env.should == { "HTTP_AUTHORIZATION" => "Bearer token-1" }
  end

  it "should build user info from the authorization header" do
    request = double("request", env: { "HTTP_AUTHORIZATION" => "Bearer token-2" })

    context = BlueFactory::RequestContext.new(request)

    context.user.should be_a(BlueFactory::UserInfo)
    context.user.token.should == "token-2"
  end

  it "should report when auth is present" do
    request = double("request", env: { "HTTP_AUTHORIZATION" => "Bearer token-3" })

    context = BlueFactory::RequestContext.new(request)

    context.has_auth?.should be true
  end

  it "should report when auth is missing" do
    request = double("request", env: {})

    context = BlueFactory::RequestContext.new(request)

    context.has_auth?.should be false
  end
end
