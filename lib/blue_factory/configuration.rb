require_relative 'modules/configurable'
require_relative 'modules/feeds'

module BlueFactory
  extend Configurable
  extend Feeds

  configurable :publisher_did, :hostname

  def self.service_did
    'did:web:' + hostname
  end
end
