module BlueFactory

  #
  # @abstract This is not a real class, but it shows what *your* feed class should look like.
  #
  # Abstract interface describing the API that the feed class that will be handling the requests
  # sent to `getFeedSkeleton`, which you pass to {BlueFactory::Feeds#add_feed}, is expected to have.
  #
  # All methods except {#get_posts} are only used briefly when submitting the feed as a record
  # using the `bluesky:publish` rake task, so only {#get_posts} is really required during normal
  # day to day operation.
  #

  class FeedHandler

    # The main method required to serve a feed. It accepts a hash of query params and optionally
    # a request context object, and is expected to return a hash of data with URIs of posts to
    # be displayed.
    #
    # The response hash should include:
    #
    # - `:posts` *(Array<String, Hash>)* — an array of posts (see below)
    # - `:cursor` *(String)* — optionally, a cursor to be passed when loading the next page
    # - `:req_id` *(String)* — optionally, a request ID that will be passed with "interactions"
    #
    # A post in `:posts` can be either a string with the AT URI of the post, or a hash with fields:
    #
    # - `:post` *(String)* — the AT URI of the post
    # - `:context` *(String)* — optionally, a context string that will be passed with "interactions"
    # - `:reason` *(Hash)* — optionally, a reason why a post appears in the feed:
    #     - `{ :repost => repost_uri }` — the post is displayed because someone reposted it (the uri points to a repost record)
    #     - `{ :pin => true }` — the post is pinned at the top of the feed
    #
    # @example Simple posts response
    #   {
    #     posts: [
    #       "at://.../app.bsky.feed.post/...",
    #       "at://.../app.bsky.feed.post/...",
    #       "at://.../app.bsky.feed.post/...",
    #       ...
    #     ],
    #     cursor: "1760639159"
    #   }
    #     
    # @example More complex response
    #   {
    #     posts: [
    #       {
    #         post: "at://.../app.bsky.feed.post/...",
    #         reason: { pin: true }
    #       },
    #       "at://.../app.bsky.feed.post/...",
    #       "at://.../app.bsky.feed.post/...",
    #       "at://.../app.bsky.feed.post/...",
    #       {
    #         post: "at://.../app.bsky.feed.post/...",
    #         reason: { repost: "at://.../app.bsky.feed.repost/..." },
    #         context: 'qweqweqwe'
    #       },
    #       "at://.../app.bsky.feed.post/...",
    #       ...
    #     ],
    #     cursor: "1760639159",
    #     req_id: "req2048"
    #   }
    #
    # @example User authorization
    #   def get_posts(params, context)
    #     if AUTHORIZED_USERS.include?(context.user.raw_did)
    #       # ...
    #     else
    #       raise BlueFactory::AuthorizationError, "You shall not pass!"
    #     end
    #   end
    #
    # @overload get_posts(params)
    #   Use this version if you don't need the context object.
    #
    #   @param params [Hash] the received query params
    #
    #   @option params [String] :feed
    #     the AT URI of the feed record
    #   @option params [String, nil] :cursor
    #     the cursor returned from the last response (the format is chosen by you)
    #   @option params [Integer, nil] :limit
    #     requested number of posts (between 1 and 100)
    #
    #   @raise [InvalidRequestError] if the request is invalid for some reason (e.g. bad cursor format)
    #   @return [Hash] post data
    #
    # @overload get_posts(params, context)
    #   Use this version if you want to be passed the context object.
    #
    #   @param params [Hash] the received query params
    #   @param context [RequestContext] request context
    #
    #   @option params [String] :feed
    #     the AT URI of the feed record
    #   @option params [String, nil] :cursor
    #     the cursor returned from the last response (the format is chosen by you)
    #   @option params [Integer, nil] :limit
    #     requested number of posts (between 1 and 100)
    #
    #   @raise [AuthorizationError] if the requesting user is not authorized to see this feed
    #   @raise [InvalidRequestError] if the request is invalid for some reason (e.g. bad cursor format)
    #   @return [Hash] post data

    def get_posts(params, context = nil)
    end

    # Returns the name of the feed that will be shown to the user in the app.
    #
    # This name is displayed not only in the header and in link cards, but also in the pinned feeds
    # tabs and the right sidebar on the desktop, so it should not be too long, ideally 1-3 words.
    #
    # @return [String]

    def display_name
    end

    # (optional) Longer description of the feed, which explains how the feed works and what kind of
    # content it serves.
    #
    # @return [String, nil]

    def description
    end

    # (optional) Path of the image file which will be used as the feed's avatar (PNG or JPG).
    #
    # @return [String, nil]

    def avatar_file
    end

    # (optional) Special feed type - return `:video` for video feeds.
    #
    # @return [String, nil]

    def content_mode
    end

    # (optional) Return true to opt-in to receiving interactions from users viewing the feed.
    #
    # @see Interaction
    # @return [Boolean]

    def accepts_interactions
    end

    private_class_method :new
  end
end
