require_relative 'blue_factory/configuration'
require_relative 'blue_factory/server'
require_relative 'blue_factory/version'

#
# This is the main module of the library, through which you configure the feed service.
#
# @example Configuring the server and feeds
#   require 'blue_factory'
#
#   BlueFactory.set :publisher_did, 'did:plc:qwertyuiopasdf'
#   BlueFactory.set :hostname, 'feeds.example.com'
#
#   BlueFactory.add_feed 'photos', PhotographyFeed.new
#
# @example Handling interactions
#   BlueFactory.on_interactions do |interactions, context|
#     interactions.each do |i|
#       unless i.type == :seen
#         puts "[#{Time.now}] #{context.user.raw_did}: #{i.type} #{i.item}"
#       end
#     end
#   end
#

module BlueFactory

  # The collection NSID of a Bluesky feed generator service.
  FEED_GENERATOR_TYPE = 'app.bsky.feed.generator'
end
