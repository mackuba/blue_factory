require_relative 'modules/configurable'
require_relative 'modules/interactions'
require_relative 'modules/feeds'

module BlueFactory
  extend Configurable
  extend Feeds
  extend Interactions

  #
  # The server's `did:web:` service DID built from the configured hostname.
  # @return [String]
  #
  def self.service_did
    'did:web:' + hostname
  end

  #
  # Current application environment, usually `:development` or `:production`. It's read from the
  # env variables `APP_ENV` or `RACK_ENV`, or `:development` by default.
  #
  # @return [Symbol]
  #
  def self.environment
    (ENV['APP_ENV'] || ENV['RACK_ENV'] || :development).to_sym
  end

  # @!method self.hostname
  #   The hostname on which the feed server runs. Configured through {#set}.
  #   @return [String, nil]

  # @!method self.publisher_did
  #   The DID of the account publishing the feeds. Configured through {#set}.
  #   @return [String, nil]

  configurable :publisher_did, :hostname
end
