module BlueFactory
  module Feeds
    def self.extended(target)
      target.instance_variable_set('@feeds', {})
    end

    def add_feed(key, feed_class)
      @feeds[key.to_s] = feed_class
    end

    def all_feeds
      @feeds.keys
    end

    def get_feed(key)
      @feeds[key.to_s]
    end
  end
end
