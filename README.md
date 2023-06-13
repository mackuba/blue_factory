# BlueFactory 🏭

A Ruby gem for hosting custom feeds for Bluesky


## What does it do

BlueFactory is a Ruby library which helps you build a web service that hosts custom feeds a.k.a. "[feed generators](https://github.com/bluesky-social/feed-generator)" for the Bluesky social network. It implements a simple HTTP server based on [Sinatra](https://sinatrarb.com) which provides the required endpoints for the feed generator interface. You need to provide the content for the feed by making a query to your preferred local database.

A feed server will usually be run together with a second piece of code that streams posts from the Bluesky "firehose" stream, runs them through some kind of filter and saves some or all of them to the database. To build that part, you can use my other Ruby gem [Skyfall](https://github.com/mackuba/skyfall).


## Installation

    gem install blue_factory


## Usage

The server is configured through the `BlueFactory` module. The two required settings are:

- `publisher_did` - DID identifier of the account that you will publish the feed on (the string that starts with `did:plc:...`)
- `hostname` - the hostname on which the feed service will be run

You also need to configure at least one feed by passing a feed key and a feed object. The key is the identifier that will appear at the end of the feed URI - ideally something short and lowercase. The object is anything that implements the single required method `get_posts` (could be a class, a module or an instance).

So a simple setup could look like this:

```rb
require 'blue_factory'

BlueFactory.set :publisher_did, 'did:plc:loremipsumqwerty'
BlueFactory.set :hostname, 'feeds.example.com'

BlueFactory.add_feed 'starwars', StarWarsFeed.new
```


### The feed object

The `get_posts` method of the feed object should:

- accept a single `params` argument which is a hash with fields: `:feed`, `:cursor` and `:limit` (the last two are optional)
- return a hash with two fields: `:cursor` and `:posts`

The `:feed` is the `at://` URI of the feed. The `:cursor` param, if included, should be a cursor returned by your feed from one of the previous requests, so it should be in the format used by the same function - but anyone can call the endpoint with any params, so you should validate it. The cursor is used for pagination to provide more pages further down in the feed (the first request to load the top of the feed doesn't include a cursor).

The `:limit`, if included, should be a numeric value specifying the number of posts to return, and you should return at most that many posts in response. According to the spec, the maximum allowed value for the limit is 100, but again, you should verify this. The default limit is 50.

The `:cursor` that you return is some kind of string that encodes the offset in the feed for a request for the next page. The structure of the cursor is something for you to decide, and it could possibly be a very long string (the actual length limit is uncertain). See the readme of the official [feed-generator repo](https://github.com/bluesky-social/feed-generator#pagination) for some guidelines on how to construct cursor strings.

And finally, the `:posts` value should be an array of posts, returned as `at://` URI strings only. The Bluesky server that makes the request for the feed will provide all the other data for the posts based on the URIs you return.

If you determine that the request is somehow invalid (e.g. the cursor doesn't match what you expect), you can also raise a `BlueFactory::InvalidRequestError` error, which will return a JSON error message with status 400. 

An example implementation could look like this:

```rb
require 'time'

class StarWarsFeed
  def get_posts(params)
    limit = check_query_limit(params)
    query = Post.select('uri, time').order('time DESC').limit(limit)

    if params[:cursor].to_s != ""
      time = Time.at(params[:cursor].to_i)
      query = query.where("time < ?", time)
    end

    posts = query.to_a
    last = posts.last
    cursor = last && last.time.to_i.to_s

    { cursor: cursor, posts: posts.map(&:uri) }
  end

  def check_query_limit(params)
    if params[:limit]
      limit = params[:limit].to_i
      (limit < 0) ? 0 : (limit > MAX_LIMIT ? MAX_LIMIT : limit)
    else
      DEFAULT_LIMIT
    end
  end
end
```

### Starting the server

The server itself is run using the `BlueFactory::Server` class, which is a subclass of `Sinatra::Base` and is used as described in the [Sinatra documentation](https://sinatrarb.com/intro.html) (as a "modular application").

In development, you can launch it using:

```rb
BlueFactory::Server.run!
```

In production, you will probably want to create a `config.ru` file that instead runs it from the Rack interface:

```rb
run BlueFactory::Server
```

Then, you would configure your preferred Ruby app server like Passenger, Unicorn or Puma to run the server using that config file and configure the main HTTP server (Nginx, Apache) to route requests on the given hostname to that app server.

As an example, an Nginx configuration for a site that runs the server via Passenger could look something like this:

```
server {
  server_name feeds.example.com;
  listen 443 ssl;

  passenger_enabled on;
  root /var/www/feeds/current/public;

  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

  access_log /var/log/nginx/feeds-access.log combined buffer=16k flush=10s;
  error_log /var/log/nginx/feeds-error.log;
}
```

### Additional configuration & customizing

You can use the [Sinatra API](https://sinatrarb.com/intro.html#configuration) to do any additional configuration, like changing the server port, enabling/disabling logging and so on.

For example, you can change the port used in development with:

```rb
BlueFactory::Server.set :port, 7777
```

You can also add additional routes, e.g. to make a redirect or print something on the root URL:

```rb
BlueFactory::Server.get '/' do
  redirect 'https://github.com/mackuba/blue_factory'
end
```


## Publishing the feed

When your feed server is ready and deployed to the production server, you can use the included `bluesky:publish` Rake task to upload the feed configuration to the Bluesky network. To do that, add this line to your `Rakefile`:

```rb
require 'blue_factory/rake'
```

You also need to load your `BlueFactory` configuration and your feed classes here, so it's recommended that you extract this configuration code to some kind of init file that can be included in the `Rakefile`, `config.ru` and elsewhere if needed.

To publish the feed, you will need to provide some additional info about the feed, like its public name, through a few more methods in the feed object (the same one that responds to `#get_posts`):

- `display_name` (required) - the publicly visible name of your feed, e.g. "WWDC 23" (should be something short)
- `description` (optional) - a longer (~1-2 lines) description of what the feed does, displayed on the feed page as the "bio"
- `avatar_file` (optional) - path to an avatar image from the project's root (PNG or JPG)

When you're ready, run the rake task passing the feed key (you will be asked for the uploader account's password):

```
bundle exec rake bluesky:publish KEY=wwdc
```

## Credits

Copyright © 2023 Kuba Suder ([@mackuba.eu](https://bsky.app/profile/mackuba.eu)).

The code is available under the terms of the [zlib license](https://choosealicense.com/licenses/zlib/) (permissive, similar to MIT).

Bug reports and pull requests are welcome 😎
