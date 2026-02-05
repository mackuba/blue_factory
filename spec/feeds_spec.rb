require 'spec_helper'

describe BlueFactory do
  class TestFeed
    def get_posts(params)
    end
  end

  before do
    BlueFactory.instance_variable_set("@feeds", {})
  end

  describe '.add_feed' do
    it 'should register given feed' do
      feed_one = TestFeed.new
      feed_two = TestFeed.new
      feed_three = TestFeed.new

      BlueFactory.add_feed('alpha', feed_one)
      BlueFactory.add_feed('beta', feed_two)
      BlueFactory.add_feed('Longest-Allowed', feed_three)

      BlueFactory.feed_keys.should == %w[alpha beta Longest-Allowed]
      BlueFactory.all_feeds.should == [feed_one, feed_two, feed_three]

      BlueFactory.get_feed('alpha').should == feed_one
      BlueFactory.get_feed(:beta).should == feed_two
    end

    it 'should raise an error for invalid keys' do
      bad_keys = [
        1,
        :foo,
        { blue: true },
        ['a', 'b'],
        '',
        'blue sky',
        'gnu/linux',
        'ohno!',
        '🦡',
        'Łódź',
      ]

      bad_keys.each do |key|
        expect { BlueFactory.add_feed(key, TestFeed.new) }.to raise_error(BlueFactory::ConfigurationError)
      end
    end

    it 'should not raise an error for very long keys' do
      name = 'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch'

      expect { BlueFactory.add_feed(name, TestFeed.new) }.to_not raise_error
    end

    it "should raise an error when the feed doesn't have a get_posts method" do
      expect { BlueFactory.add_feed('object', Object.new) }.to raise_error(BlueFactory::InvalidFeedClassError)
    end
  end
end
