# frozen_string_literal: true

require_relative "lib/blue_factory/version"

Gem::Specification.new do |spec|
  spec.name = "blue_factory"
  spec.version = BlueFactory::VERSION
  spec.authors = ["Kuba Suder"]
  spec.email = ["jakub.suder@gmail.com"]

  spec.summary = "Write a short summary, because RubyGems requires one."
  spec.description = "Write a longer description or delete this line."
  spec.homepage = "https://github.com/mackuba/blue_factory"

  spec.license = "Zlib"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/mackuba/blue_factory/issues",
    "changelog_uri"     => "https://github.com/mackuba/blue_factory/blob/master/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/mackuba/blue_factory",
  }

  spec.files = Dir.chdir(__dir__) do
    Dir['*.md'] + Dir['*.txt'] + Dir['lib/**/*'] + Dir['sig/**/*']
  end

  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra', '~> 3.0'
end
