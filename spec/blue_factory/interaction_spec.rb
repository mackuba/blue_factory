# frozen_string_literal: true

require "spec_helper"

describe BlueFactory::Interaction do
  it "should map the interaction data to attributes" do
    data = {
      "item" => "at://did:plc:abc123/app.bsky.feed.post/def456",
      "event" => "app.bsky.feed.defs#interactionLike",
      "feedContext" => "ctx-1",
      "reqId" => "req-99"
    }

    interaction = BlueFactory::Interaction.new(data)

    interaction.item.should == "at://did:plc:abc123/app.bsky.feed.post/def456"
    interaction.event.should == "app.bsky.feed.defs#interactionLike"
    interaction.context.should == "ctx-1"
    interaction.req_id.should == "req-99"
    interaction.type.should == :like
  end

  it "should set type to nil for unknown events" do
    data = {
      "item" => "at://did:plc:abc123/app.bsky.feed.post/def456",
      "event" => "app.bsky.feed.defs#interactionUnknown"
    }

    interaction = BlueFactory::Interaction.new(data)

    interaction.type.should be nil
  end
end
