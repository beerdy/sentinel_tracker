lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sentinel_tracker/version"

Gem::Specification.new do |spec|
  spec.name = "sentinel_tracker"
  spec.version = SentinelTracker::VERSION
  spec.authors = ["Codex"]
  spec.email = ["devnull@castle.local"]

  spec.summary = "Security audit gem for targeted user activity tracking."
  spec.description = "Provides middleware and async pipeline for request audit of a configured target user."
  spec.homepage = "https://castle.local/sentinel_tracker"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "app/**/*",
      "lib/**/*",
      "docs/**/*.md",
      "README.md",
      "Rakefile"
    ]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 4.2", "< 6.1"
  spec.add_dependency "activerecord", ">= 4.2", "< 6.1"
  spec.add_dependency "actionpack", ">= 4.2", "< 6.1"
  spec.add_dependency "activesupport", ">= 4.2", "< 6.1"
  spec.add_dependency "faraday", ">= 0.15", "< 3.0"
  spec.add_dependency "railties", ">= 4.2", "< 6.1"

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
