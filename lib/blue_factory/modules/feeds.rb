require_relative '../errors'

module BlueFactory

  #
  # @api private
  #
  # Adds configuration for feeds and provides lookup of configured feeds to {BlueFactory}.
  # Use these APIs through the main {BlueFactory} module, not directly.
  #

  module Feeds
    def self.extended(target)
      target.instance_variable_set('@feeds', {})
    end

    RKEY_REGEXP = /\A[A-Za-z0-9\.\-_:~]+\z/

    #
    # Registers a feed handler for a given rkey. The full AT URI of the feed generator, which is
    # listed in `describeFeedGenerator` and expected in the `feed` parameter to `getFeedSkeleton`
    # will be: `"at://#{publisher_did}/app.bsky.feed.generator/#{key}"`. The key should be a string
    # no longer than 15 characters and should not contain slashes, preferably only lowercase letters,
    # digits and hyphens.
    #
    # The feed handler is expected to be an object which has a `#get_posts` method which accepts
    # requests routed from the BlueFactory server and returns post data in a specified format.
    # See the abstract {FeedHandler} class for a description of the expected API.
    #
    # @api public
    # @param key [String] the feed rkey
    # @param feed_handler [#get_posts] feed implementation object
    # @raise [ConfigurationError] if the key has invalid format
    #
    def add_feed(key, feed_handler)
      validate_key(key)
      validate_feed(key, feed_handler)

      @feeds[key.to_s] = feed_handler
    end

    #
    # Lists all configured feed keys.
    #
    # @api public
    # @return [Array<String>]
    #
    def feed_keys
      @feeds.keys
    end

    #
    # Returns a feed handler configured for a given rkey.
    #
    # @api public
    # @param key [String] feed key
    # @return [#get_posts, nil] feed object, if registered
    #
    def get_feed(key)
      @feeds[key.to_s]
    end

    #
    # Returns an array of all registered feed handler objects.
    #
    # @api public
    # @return [Array<#get_posts>]
    #
    def all_feeds
      @feeds.values
    end


    private

    def validate_key(key)
      raise ConfigurationError, "Key must be a string (got: #{key.inspect})" unless key.is_a?(String)
      raise ConfigurationError, "Key must not be empty" if key == ''
      raise ConfigurationError, "Key #{key.inspect} contains invalid characters" if key !~ RKEY_REGEXP
    end

    def validate_feed(key, feed)
      get_posts = feed.method(:get_posts) rescue nil

      if get_posts.nil?
        raise InvalidFeedClassError, "The feed object for '#{key}' is missing required method `get_posts`"
      end
    end

    private_class_method :extended
  end
end
