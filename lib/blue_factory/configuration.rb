require_relative 'modules/configurable'
require_relative 'modules/interactions'
require_relative 'modules/feeds'
require_relative 'errors'

module BlueFactory
  extend Configurable
  extend Feeds
  extend Interactions

  #
  # The server's `did:web:` service DID built from the configured hostname.
  # @return [String]
  # @raise [ConfigurationError] if the hostname is not set
  #
  def self.service_did
    if hostname.nil?
      raise ConfigurationError, "The `hostname` property is not set. Set it with: BlueFactory.set(:hostname, 'example.com')"
    end

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
