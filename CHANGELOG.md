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
