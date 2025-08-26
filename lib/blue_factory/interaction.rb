module BlueFactory
  class Interaction
    EVENTS = {
      'app.bsky.feed.defs#requestLess' => :request_less,
      'app.bsky.feed.defs#requestMore' => :request_more
    }

    attr_reader :item, :event, :context, :req_id, :type

    def initialize(data)
      @item = data['item']
      @event = data['event']
      @context = data['feedContext']
      @req_id = data['reqId']
      @type = EVENTS[@event]
    end
  end
end
