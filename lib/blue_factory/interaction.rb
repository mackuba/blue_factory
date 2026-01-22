module BlueFactory

  #
  # Represents a single feed interaction event.
  #
  # Interactions are various kinds of events registered while a user is browsing the feed,
  # either automatically in response to their browsing (e.g. "post seen", "post liked") or as
  # explicit actions taken consciously by the user, with the intention of passing information back
  # to the feed operator (clicking "show more like this" / "show less like this" in the post context
  # menu). Interactions are submitted through the `app.bsky.feed.sendInteractions` endpoint and may
  # be batched.
  #
  # When that endpoint is called, BlueFactory wraps the submitted interaction objects in
  # instances of {Interaction} and passes them to the configured handler block, which is set up
  # through {Interactions#on_interactions} or {Interactions#interactions_handler=} on {BlueFactory}.
  #
  # Note: the {Interaction} objects include info about what interaction has been triggered and
  # on which specific post (post AT URI), but they don't include info in which *feed* it has been
  # triggered. If you have multiple feeds configured and need to know which feed an interaction
  # is from, you need to include either a `context` field (assigned to a specific post) or a
  # `req_id` field (assigned to the whole request) in the data response returned from `get_posts`.
  #

  class Interaction

    #
    # Mapping of interaction identifiers in the protocol to short code symbols.
    #

    EVENTS = {
      # user has liked a post in the feed
      'app.bsky.feed.defs#interactionLike' => :like,

      # user has quoted a post in the feed
      'app.bsky.feed.defs#interactionQuote' => :quote,

      # user has replied to a post in the feed
      'app.bsky.feed.defs#interactionReply' => :reply,

      # user has reposted a post in the feed
      'app.bsky.feed.defs#interactionRepost' => :repost,

      # user has scrolled down to the given post
      'app.bsky.feed.defs#interactionSeen' => :seen,

      # user has clicked "show less like this" on a post
      'app.bsky.feed.defs#requestLess' => :request_less,

      # user has clicked "show more like this" on a post
      'app.bsky.feed.defs#requestMore' => :request_more
    }

    # @return [String] the URI of the post
    attr_reader :item

    # @return [String] the protocol identifier of the interaction type
    attr_reader :event

    # @return [Symbol, nil] short code symbol of the interaction type
    attr_reader :type

    # @return [String, nil] optional post context from the original response
    attr_reader :context

    # @return [String, nil] optional request identifier from the original response
    attr_reader :req_id

    #
    # @param data [Hash] interaction JSON data
    #
    def initialize(data)
      @item = data['item']
      @event = data['event']
      @context = data['feedContext']
      @req_id = data['reqId']
      @type = EVENTS[@event]
    end
  end
end
