# BlueFactory 🏭

A Ruby gem for hosting custom feeds for Bluesky.

> [!NOTE]
> ATProto Ruby gems collection: [skyfall](https://tangled.org/@mackuba.eu/skyfall) | [blue_factory](https://tangled.org/@mackuba.eu/blue_factory) | [minisky](https://tangled.org/@mackuba.eu/minisky) | [didkit](https://tangled.org/@mackuba.eu/didkit)


## What does it do

BlueFactory is a Ruby library which helps you build a web service that hosts custom feeds a.k.a. "[feed generators](https://github.com/bluesky-social/feed-generator)" for the Bluesky social network. It implements a simple HTTP server based on [Sinatra](https://sinatrarb.com) which provides the required endpoints for the feed generator interface. You need to provide the content for the feed by making a query to your preferred local database.

A feed server will usually be run together with a second piece of code that streams posts from the Bluesky "firehose" stream, runs them through some kind of filter and saves some or all of them to the database. To build that part, you can use my other Ruby gem [Skyfall](https://tangled.org/@mackuba.eu/skyfall).


## Installation

Add this to your `Gemfile`:

    gem 'blue_factory', '~> 0.2'


## Usage

The server is configured through the `BlueFactory` module. The two required settings are:

- `publisher_did` – DID identifier of the account that you will publish the feed on (the string that starts with `did:plc:...`)
- `hostname` – the hostname on which the feed service will be run

You also need to configure at least one feed by passing a feed key and a feed object. The key is the identifier (rkey) that will appear at the end of the feed URI – it must only contain characters that are valid in URLs (preferably all lowercase) and it can't be longer than 15 characters. The feed object is anything that implements the single required method `get_posts` (could be a class, a module or an instance).

So a simple setup could look like this:

```rb
require 'blue_factory'

BlueFactory.set :publisher_did, 'did:plc:loremipsumqwerty'
BlueFactory.set :hostname, 'feeds.example.com'

BlueFactory.add_feed 'starwars', StarWarsFeed.new
```


## The feed API

The `get_posts` method of the feed object should:

- accept a `params` argument which is a hash with fields: `:feed`, `:cursor` and `:limit` (the last two are optional)
- optionally, it can accept a second `context` argument with additional info like the authenticated user's DID (see "[Authentication](#authentication)")
- return a response hash with the posts data, with at least one key `:posts`


### Parameters

The `:feed` is the `at://` URI of the feed.

The `:cursor` param, if included, should be a cursor returned earlier by your feed from one of the previous requests, so it should be in the format used by the same function – but anyone can call the endpoint with any params, so you should validate it. The cursor is used for pagination to provide more pages further down in the feed (the first request to load the top of the feed doesn't include a cursor).

The `:limit`, if included, should be a numeric value specifying the number of posts to return, and you should return at most that many posts in response. According to the spec, the maximum allowed value for the limit is 100, but again, you should verify this. The default limit is 50.

### Response

The `:posts` in the response hash that you return should be an array of URIs of posts. You only return the URI of a post to the Bluesky server, not all contents of the post like text and embed data – the server will "hydrate" the posts with all the other data from its own database.

The posts in the `get_posts` response from your feed object can be either:

- strings with the `at://` URI of a post
- hashes with the URI in the `:post` field and additional metadata

A combination of both is also allowed – some posts can be returned as URI strings, and some as hashes.

A response hash should also include a `:cursor`, which is some kind of string that encodes the offset in the feed, which will be passed back to you in a request for the next page. The structure of the cursor is something for you to decide, and it could possibly be a very long string (the actual length limit is uncertain). See the readme of the official [feed-generator repo](https://github.com/bluesky-social/feed-generator#pagination) for some guidelines on how to construct cursor strings. In practice, it's usually some combination of a timestamp in some form and/or an internal record ID, possibly with some separator like `:` or `-`.

The response can also include a `:req_id`, which is a "request ID" assigned to this specific request (again, the form of which is decided by you), which may be useful for processing [interactions](#handling-feed-interactions).

#### Post metadata:

If the post entry in `:posts` array is a hash, apart from the `:post` field with the URI it can include:

* `:context` – some kind of internal metadata about this specific post in this specific response, e.g. identifying how this post ended up in that response, used for processing [interactions](#handling-feed-interactions)
* `:reason` – information about why this post is being displayed, which can be shown to the user; currently supported reasons are:
  - `{ :repost => repost_uri }` – the post is displayed because someone reposted it (the uri points to a `app.bsky.feed.repost` record)
  - `{ :pin => true }` – the post is pinned at the top of the feed

So the complete structure of your reponse in full form may look something like this:

```rb
{
  posts: [
    {
      post: "at://.../app.bsky.feed.post/...",
      reason: { pin: true }
    },
    "at://.../app.bsky.feed.post/...",
    "at://.../app.bsky.feed.post/...",
    "at://.../app.bsky.feed.post/...",
    {
      post: "at://.../app.bsky.feed.post/...",
      reason: { repost: "at://.../app.bsky.feed.repost/..." },
      context: 'qweqweqwe'
    },
    "at://.../app.bsky.feed.post/...",
    ...
  ],
  cursor: "1760639159",
  req_id: "req2048"
}
```

### Error handling

If you determine that the request is somehow invalid (e.g. the cursor doesn't match what you expect), you can also raise a `BlueFactory::InvalidRequestError` error, which will return a JSON error message with status 400. The `message` of the exception might be shown to the user in an error banner.

### Example code

A simple example implementation could look like this:

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

## Running the server

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

## Authentication

Feeds are authenticated using a technology called [JSON Web Tokens](https://jwt.io). If a user is logged in, when they open, refresh or scroll down a feed in their app, requests are made to the feed service from the Bluesky network's IP address with user's authentication token in the `Authorization` HTTP header. (This is not the same kind of token as the access token that you use to make API calls – it does not let you perform any actions on user's behalf.)

At the moment, Blue Factory handles authentication in a very simplified way – it extracts the user's DID from the authentication header, but it does not verify the signature. This means that anyone with some programming knowledge can trivially prepare a fake token and make requests to the `getFeedSkeleton` endpoint as a different user.

As such, this authentication should not be used for anything critical. It may be used for things like logging, analytics, or as "security by obscurity" to just discourage others from accessing the feed in the app. You can also use this to build personalized feeds, as long as it's not a problem that the user DID may be fake.

To use this simple authentication, make a `get_posts` method that accepts two arguments: the second argument is a `context`, from which you can get user info via `context.user.raw_did`. `context.user.token` returns the whole Base64-encoded JWT token.

So this way you could, for example, return an empty list when the user is not authorized to use it:

```rb
class HiddenFeed
  def get_posts(params, context)
    if AUTHORIZED_USERS.include?(context.user.raw_did)
      # ...
    else
      { posts: [] }
    end
  end
end
```

Alternatively, you can raise a `BlueFactory::AuthorizationError` with an optional custom message. This will return a 401 status response to the Bluesky app, which will make it display the pink error banner in the app:

```rb
class HiddenFeed
  def get_posts(params, context)
    if AUTHORIZED_USERS.include?(context.user.raw_did)
      # ...
    else
      raise BlueFactory::AuthorizationError, "You shall not pass!"
    end
  end
end
```

<p><img width="400" src="https://github.com/mackuba/blue_factory/assets/28465/9197c0ec-9302-4ca0-b06c-3fce2e0fa4f4"></p>


### Unauthenticated access

Please note that there might not be any user information in the context – this will happen if the authentication header is not set at all. Since the [bsky.app](https://bsky.app) website can be accessed while logged out, people can also access your feeds this way. In that case, `context.user` will exist, but `context.user.token` and `context.user.raw_did` will be nil. You can also use the `context.has_auth?` method as a shortcut.

If you want the feed to only be available to logged in users (even if it's a non-personalized feed), simply raise an `AuthorizationError` if there's no authentication info:

```rb
class RestrictedFeed
  def get_posts(params, context)
    if !context.has_auth?
      raise BlueFactory::AuthorizationError, "Log in to see this feed"
    end

    # ...
  end
end
```


## Handling feed interactions

If that makes sense in your feed, you can opt in to receiving "feed interaction" events from the users who view it. Interactions are either explicit actions that the user takes – they can press the "Show more like this" or "Show less like this" buttons in the context menu on a post they see in your feed – or implicit events that get sent automatically.

To receive interactions, your feed needs to opt in to that (the "Show more/less" buttons are only displayed in your feed if you do). This is done by setting an `acceptsInteractions` field in the feed generator record – in BlueFactory, you need to add an `accepts_interactions` property or method to your feed object and return `true` from it (and re-publish the feed if it was already live).

The interactions are sent to your feed by making a `POST` request to the `app.bsky.feed.sendInteractions` endpoint. BlueFactory passes these to you using a handler which you configure this way:

```rb
BlueFactory.on_interactions do |interactions, context|
  interactions.each do |i|
    unless i.type == :seen
      puts "[#{Time.now}] #{context.user.raw_did}: #{i.type} #{i.item}"
    end
  end
end
```

or, alternatively:

```rb
BlueFactory.interactions_handler = proc { ... }
```

There is one shared handler for all the feeds you're hosting – to find out what a given interaction is about, you need to add the fields `:req_id` and/or `:context` to the feed response (see "[Feed API – Response](#response)").

An `Interaction` has such properties:

- `item` – at:// URI of a post the interaction is about
- `event` – name of the interaction type as specified in the lexicon, e.g. `app.bsky.feed.defs#requestLess`
- `context` – the context that was assigned in your response to this specific post
- `req_id` – the request ID that was assigned in your response to the request
- `type` – a short symbolic code of the interaction type

Currently enabled interaction types are:

- `:request_more` – user asked to see more posts like this
- `:request_less` – user asked to see fewer posts like this
- `:like` – user pressed like on the post
- `:repost` – user reposted the post
- `:reply` – user replied to the post
- `:quote` – user quoted the post
- `:seen` – user has seen the post (scrolled down to it)


## Additional configuration & customizing

You can use the [Sinatra API](https://sinatrarb.com/intro.html#configuration) to do any additional configuration, like changing the server port, enabling/disabling logging and so on.

For example, you can change the port used in development with:

```rb
BlueFactory::Server.set :port, 7777
```

You can also add additional routes, e.g. to make a redirect or print something on the root URL:

```rb
BlueFactory::Server.get '/' do
  redirect 'https://welcome.example.com'
end
```


## Publishing the feed

When your feed server is ready and deployed to the production server, you can use the included `bluesky:publish` Rake task to upload the feed configuration to the Bluesky network. To do that, add this line to your `Rakefile`:

```rb
require 'blue_factory/rake'
```

You also need to load your `BlueFactory` configuration and your feed classes here, so it's recommended that you extract this configuration code to some kind of init file that can be included in the `Rakefile`, `config.ru` and elsewhere if needed.

To publish the feed, you will need to provide some additional info about the feed, like its public name, through a few more methods in the feed object (the same one that responds to `#get_posts`):

- `display_name` (required) – the publicly visible name of your feed, e.g. "Cat Pics" (should be something short)
- `description` (optional) – a longer (~1-2 lines) description of what the feed does, displayed on the feed page as the "bio"
- `avatar_file` (optional) – path to an avatar image from the project's root (PNG or JPG)
- `content_mode` (optional) – return `:video` to create a video feed, which is displayed with a special layout
- `accepts_interactions` (optional) – return `true` to opt in to receiving [interactions](#handling-feed-interactions)

When you're ready, run the rake task passing the feed key (you will be asked for the uploader's account password or app password):

```
bundle exec rake bluesky:publish KEY=wwdc
```

You also need to republish the feed by running the same task again any time you make changes to these properties and you want them to take effect.


## Credits

Copyright © 2025 Kuba Suder ([@mackuba.eu](https://bsky.app/profile/mackuba.eu)).

The code is available under the terms of the [zlib license](https://choosealicense.com/licenses/zlib/) (permissive, similar to MIT).

Bug reports and pull requests are welcome 😎
