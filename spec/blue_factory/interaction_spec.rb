require 'spec_helper'

describe BlueFactory::Interaction do
  let(:data) {{
    'item' => 'at://did:plc:abc123/app.bsky.feed.post/def456',
    'event' => 'app.bsky.feed.defs#interactionLike',
    'feedContext' => 'context1024',
    'reqId' => 'req99'
  }}

  it "should parse fields from the data" do
    int = BlueFactory::Interaction.new(data)

    int.item.should == "at://did:plc:abc123/app.bsky.feed.post/def456"
    int.event.should == "app.bsky.feed.defs#interactionLike"
    int.context.should == "context1024"
    int.req_id.should == "req99"
    int.type.should == :like
  end

  context 'if event type is not recognized' do
    before do
      data['event'] = 'app.bsky.feed.defs#somethingHappened'
    end

    it 'should return nil from #type' do
      int = BlueFactory::Interaction.new(data)
      int.type.should be_nil
    end

    it 'should return real identifier from #event' do
      int = BlueFactory::Interaction.new(data)
      int.event.should == 'app.bsky.feed.defs#somethingHappened'
    end
  end
end
