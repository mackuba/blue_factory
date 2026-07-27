unless ENV["GITHUB_ACTIONS"] == "true"
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    formatter SimpleCov::Formatter::HTMLFormatter.new(silent: true)
  end
end

ENV["RACK_ENV"] = "test"

require 'blue_factory'
require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.mock_with :mocha
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

def app
  BlueFactory::Server
end
