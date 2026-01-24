require 'spec_helper'

describe BlueFactory::Server do
  before do
    BlueFactory.set :hostname, 'feeds.example.com'
    BlueFactory.set :publisher_did, 'did:plc:ewvi7nxzyoun6zhxrhs64oiz'
  end

  it "returns ok" do
    get "/xrpc/app.bsky.feed.describeFeedGenerator"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to include("application/json")
  end
end
