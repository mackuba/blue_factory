require 'simplecov'

ENV["RACK_ENV"] = "test"

SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
end

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

module SimpleCov
  module Formatter
    class HTMLFormatter
      def format(result)
        # silence the stdout summary, just save the html files
        unless @inline_assets
          Dir[File.join(@public_assets_dir, "*")].each do |path|
            FileUtils.cp_r(path, asset_output_path, remove_destination: true)
          end
        end

        File.open(File.join(output_path, "index.html"), "wb") do |file|
          file.puts template("layout").result(binding)
        end
      end
    end
  end
end
