module BlueFactory
  module Feeds
    def self.extended(target)
      target.instance_variable_set('@feeds', {})
    end

    def add_feed(key, feed_class)
      validate_key(key)
      @feeds[key.to_s] = feed_class
    end

    def all_feeds
      @feeds.keys
    end

    def get_feed(key)
      @feeds[key.to_s]
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
