require 'blue_factory/configuration'
require 'blue_factory/tasks/support'
require 'io/console'

namespace :bluesky do
  desc "Publish a feed"
  task :publish do
    if ENV['KEY'].to_s == ''
      puts "Please specify feed key as KEY=feedname (the part of the feed's at:// URI after the last slash)"
      exit 1
    end

    feed_key = ENV['KEY']

    if BlueFactory.hostname.nil?
      puts "Missing server hostname: please set the hostname with `BlueFactory.set :hostname, 'example.com'`"
      exit 1
    end

    if BlueFactory.publisher_did.nil?
      puts "Missing publisher DID: please set it with `BlueFactory.set :publisher_did, 'did:plc:youridentifier'`"
      exit 1
    end

    feed = BlueFactory.get_feed(feed_key)

    if feed.nil?
      puts "No feed configured for key '#{feed_key}' - use `BlueFactory.add_feed '#{feed_key}', MyFeed.new`"
      exit 1
    end

    if feed.respond_to?(:display_name) && feed.display_name.to_s.strip != ''
      feed_display_name = feed.display_name
    else
      puts "The feed has no display name - implement a #display_name method."
      exit 1
    end

    if feed.respond_to?(:description) && feed.description.to_s.strip != ''
      feed_description = feed.description
    end

    if feed.respond_to?(:content_mode)
      case feed.content_mode
      when nil, :unspecified
        feed_content_mode = "app.bsky.feed.defs#contentModeUnspecified"
      when :video
        feed_content_mode = "app.bsky.feed.defs#contentModeVideo"
      else
        puts "Invalid content mode: #{feed.content_mode.inspect}. Accepted values: :video, :unspecified, nil."
        exit 1
      end
    end

    if feed.respond_to?(:avatar_file) && feed.avatar_file.to_s.strip != ''
      avatar_file = feed.avatar_file

      if !File.exist?(avatar_file)
        puts "Avatar file #{avatar_file} not found."
        exit 1
      end

      encoding = case avatar_file
      when /\.png$/ then 'image/png'
      when /\.jpe?g$/ then 'image/jpeg'
      else
        puts "The avatar must be either a PNG or a JPEG file."
        exit 1
      end

      avatar_data = File.read(avatar_file)
    end

    server = ENV['SERVER_URL'] || "https://bsky.social"

    print "Enter password for your publisher account (#{BlueFactory.publisher_did}): "
    password = STDIN.noecho(&:gets).chomp
    puts

    json = BlueFactory::Net.post_request(server, 'com.atproto.server.createSession', {
      identifier: BlueFactory.publisher_did,
      password: password
    })

    access_token = json['accessJwt']

    if avatar_data
      json = BlueFactory::Net.post_request(server, 'com.atproto.repo.uploadBlob', avatar_data,
        content_type: encoding, auth: access_token)

      avatar_ref = json['blob']
    end

    record = {
      did: BlueFactory.service_did,
      displayName: feed_display_name,
      description: feed_description,
      createdAt: Time.now.iso8601,
    }

    record[:avatar] = avatar_ref if avatar_ref
    record[:contentMode] = feed_content_mode if feed_content_mode

    json = BlueFactory::Net.post_request(server, 'com.atproto.repo.putRecord', {
      repo: BlueFactory.publisher_did,
      collection: BlueFactory::FEED_GENERATOR_TYPE,
      rkey: feed_key,
      record: record
    }, auth: access_token)

    puts "Feed published ✓"
  end
end
