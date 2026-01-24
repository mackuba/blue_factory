require 'spec_helper'

describe BlueFactory do
  class Feed
    def get_posts(_input); end
  end

  before do
    BlueFactory.instance_variable_set("@feeds", {})
  end

  describe '.add_feed' do
    it 'should register feeds and expose them through lookup methods' do
      feed_one = Feed.new
      feed_two = Feed.new

      BlueFactory.add_feed('alpha', feed_one)
      BlueFactory.add_feed('beta', feed_two)

      BlueFactory.feed_keys.should == %w[alpha beta]
      BlueFactory.get_feed('alpha').should == feed_one
      BlueFactory.get_feed(:beta).should == feed_two
      BlueFactory.all_feeds.should == [feed_one, feed_two]
    end

    it 'should raise an error for invalid keys' do
      expect { BlueFactory.add_feed(:invalid, Feed.new) }.to raise_error(BlueFactory::ConfigurationError)
    end

    it 'should raise an error when feed handler is missing get_posts' do
      expect { BlueFactory.add_feed('alpha', Object.new) }.to raise_error(BlueFactory::InvalidFeedClassError)
    end
  end
end
