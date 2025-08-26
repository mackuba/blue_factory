require_relative 'modules/configurable'
require_relative 'modules/interactions'
require_relative 'modules/feeds'

module BlueFactory
  extend Configurable
  extend Feeds
  extend Interactions

  def self.service_did
    'did:web:' + hostname
  end

  def self.environment
    (ENV['APP_ENV'] || ENV['RACK_ENV'] || :development).to_sym
  end

  configurable :publisher_did, :hostname, :validate_responses, :enable_unsafe_auth

  set :validate_responses, (environment != :production)

  def self.set(property, value)
    if property.to_sym == :enable_unsafe_auth
      puts "==="
      puts "WARNING: option :enable_unsafe_auth and old API get_posts(args, user_did) is deprecated and will be removed in version 0.3."
      puts "Switch to get_posts(args, context) instead and get the user DID from: context.user.raw_did."
      puts "==="
      @enable_unsafe_auth = value
    else
      super
    end
  end
end
