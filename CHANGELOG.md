## [0.3.0] - 2026-02-15

- added [YARD documentation](https://rubydoc.info/gems/blue_factory)
- added explicit `base64` dependency in gemspec
- added `MAX_LIMIT` (100) and `DEFAULT_LIMIT` (50) constants
- removed the length limit on feed rkeys, since it isn't actually limited to 15
- removed deprecated options `enable_unsafe_auth` and `validate_responses`
- fixed `rake:publish` not working with feed `description` is nil (thx @jthigpen)
- `rake:publish` shows a better error message when `createSession` requires a 2FA token
- added various additional checks:
  * `Server` checks if `BlueFactory.hostname` and `BlueFactory.publisher_did` are set before launching
  * `add_feed` checks if the key contains only valid characters
  * `add_feed` checks if the feed class has a `#get_posts` method
  * `getFeedSkeleton` ensures that the limit param is between 1 and 100 (so you don't need to check that)
  * `raw_did` checks if the extracted payload contains an `iss` key

## [0.2.1] - 2025-12-07

- updated gemspec so the gem can be used with Sinatra 4.x

## [0.2.0] - 2025-10-16

Breaking changes / deprecations:

- changed `get_posts` API to (optionally) pass a `context` as the second param instead of `current_user`; context includes the user DID as `context.user.raw_did`, and will also include a verified DID in a future version
- `enable_unsafe_auth` option is deprecated – for now, `get_posts` will still work with `(params, current_user)` if that option is set
- `validate_responses` option is deprecated – responses are now always validated, also in production

Also:

- `get_posts` response can now return each post either as an AT URI string as before, or as a hash with URI in the `:post` field
- added support for post reasons (repost, pin) via `:reason` field in the post hash
- added support for post context info via `:context` field in the post hash and request ID info via `:req_id` in the response hash
- added `accepts_interactions` property to the feed API which lets it accept user interactions feedback ("show more/less" etc.)
- added support for accepting interactions sent to `app.bsky.feed.sendInteractions` via `on_interactions` handler

## [0.1.6] - 2025-07-17

- detect PDS hostname automatically in the `bluesky:publish` Rake task

## [0.1.5] - 2025-03-20

- added support for feed content mode field (video feeds)

## [0.1.4] - 2023-08-19

- implemented partial authentication, without signature verification (`enable_unsafe_auth` option)

## [0.1.3] - 2023-07-27

- fixed incorrect response when reaching the end of the feed

## [0.1.2] - 2023-06-15

- added validation for feed rkey
- renamed `all_feeds` to `feed_keys`, `all_feeds` now returns an array of feeds

## [0.1.1] - 2023-06-13

- added a rake task for publishing the feed to Bluesky

## [0.1.0] - 2023-06-12

Initial release: working version that serves all required endpoints for the feed.
