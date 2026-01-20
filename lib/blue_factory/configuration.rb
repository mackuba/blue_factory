require_relative 'modules/configurable'
require_relative 'modules/interactions'
require_relative 'modules/feeds'

module BlueFactory
  extend Configurable
  extend Feeds
  extend Interactions

  ##
  # Builds the service DID based on the configured hostname.
  #
  # @return [String] DID of the service.
  def self.service_did
    'did:web:' + hostname
  end

  ##
  # Current application environment.
  #
  # @return [Symbol] the environment derived from APP_ENV or RACK_ENV.
  def self.environment
    (ENV['APP_ENV'] || ENV['RACK_ENV'] || :development).to_sym
  end

  ##
  # Defines configurable settings for the service.
  configurable :publisher_did, :hostname, :validate_responses, :enable_unsafe_auth

  ##
  # Sets a configuration value, with warnings for deprecated options.
  #
  # @param property [String, Symbol] configuration key
  # @param value [Object] value to assign
  # @return [void]
  def self.set(property, value)
    if property.to_sym == :enable_unsafe_auth
      puts "==="
      puts "WARNING: option :enable_unsafe_auth and old API get_posts(args, user_did) is deprecated and will be removed in version 0.3."
      puts "Switch to get_posts(args, context) instead and get the user DID from: context.user.raw_did."
      puts "==="
      @enable_unsafe_auth = value
    elsif property.to_sym == :validate_responses
      puts "==="
      puts "WARNING: option :validate_responses is deprecated and will be removed in version 0.3. " +
        "Responses are now always validated, also in production."
      puts "==="
    else
      super
    end
  end
end
