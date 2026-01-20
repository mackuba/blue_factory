module BlueFactory
  ##
  # Maintains a registry of feed classes by key.
  module Feeds
    ##
    # Initializes the feeds registry when the module is extended.
    #
    # @param target [Module] the extending module or class
    # @return [void]
    def self.extended(target)
      target.instance_variable_set('@feeds', {})
    end

    ##
    # Registers a feed class with a key.
    #
    # @param key [String] feed key
    # @param feed_class [Class] feed implementation
    # @return [void]
    # @raise [InvalidKeyError] if the key is invalid
    def add_feed(key, feed_class)
      validate_key(key)
      @feeds[key.to_s] = feed_class
    end

    ##
    # Lists all configured feed keys.
    #
    # @return [Array<String>] available feed keys
    def feed_keys
      @feeds.keys
    end

    ##
    # Retrieves a feed class by key.
    #
    # @param key [String] feed key
    # @return [Class, nil] feed class if registered
    def get_feed(key)
      @feeds[key.to_s]
    end

    ##
    # Returns all registered feed classes.
    #
    # @return [Array<Class>] feed implementations
    def all_feeds
      @feeds.values
    end

    private

    def validate_key(key)
      raise InvalidKeyError, "Key must be a string" unless key.is_a?(String)
      raise InvalidKeyError, "Key must not be empty" if key == ''
      raise InvalidKeyError, "Key must not contain a slash" if key.include?('/')
      raise InvalidKeyError, "Key must not be longer than 15 characters" if key.length > 15
    end
  end
end
