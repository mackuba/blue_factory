module BlueFactory
  ##
  # Represents a single feed interaction event.
  class Interaction
    ##
    # Mapping of event identifiers to internal symbols.
    EVENTS = {
      'app.bsky.feed.defs#interactionLike' => :like,
      'app.bsky.feed.defs#interactionQuote' => :quote,
      'app.bsky.feed.defs#interactionReply' => :reply,
      'app.bsky.feed.defs#interactionRepost' => :repost,
      'app.bsky.feed.defs#interactionSeen' => :seen,
      'app.bsky.feed.defs#requestLess' => :request_less,
      'app.bsky.feed.defs#requestMore' => :request_more
    }

    # @return [String] the URI of the feed item
    attr_reader :item
    # @return [String] the raw interaction event identifier
    attr_reader :event
    # @return [String, nil] optional feed context
    attr_reader :context
    # @return [String, nil] optional request identifier
    attr_reader :req_id
    # @return [Symbol, nil] normalized event type
    attr_reader :type

    ##
    # @param data [Hash] interaction payload from the API
    def initialize(data)
      @item = data['item']
      @event = data['event']
      @context = data['feedContext']
      @req_id = data['reqId']
      @type = EVENTS[@event]
    end
  end
end
