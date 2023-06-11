require_relative 'modules/configurable'
require_relative 'modules/feeds'

module BlueFactory
  extend Configurable
  extend Feeds

  def self.service_did
    'did:web:' + hostname
  end

  def self.environment
    (ENV['APP_ENV'] || ENV['RACK_ENV'] || :development).to_sym
  end

  configurable :publisher_did, :hostname, :validate_responses

  set :validate_responses, (environment != :production)
end
