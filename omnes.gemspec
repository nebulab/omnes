# frozen_string_literal: true

require_relative "lib/omnes/version"

Gem::Specification.new do |spec|
  spec.name = "omnes"
  spec.version = Omnes::VERSION
  spec.authors = ["Marc Busqué"]
  spec.email = ["marc@lamarciana.com"]

  spec.summary = "Pub/Sub for ruby"
  spec.description = <<~MSG
    Omnes is a Ruby library implementing the publish-subscribe pattern. This
    pattern allows senders of messages to be decoupled from their receivers. An
    Event Bus acts as a middleman where events are published while interested
    parties can subscribe to them.
  MSG
  spec.homepage = "https://github.com/nebulab/omnes"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activejob"
  spec.add_development_dependency "redcarpet", "~> 3.5"
  spec.add_development_dependency "sidekiq", "~> 6.4"
  spec.add_development_dependency "yard", "~> 0.9"
end
