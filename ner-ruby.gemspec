# frozen_string_literal: true

require_relative "lib/ner_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "ner-ruby"
  spec.version = NerRuby::VERSION
  spec.authors = ["Johannes Dwi Cahyo"]
  spec.email = ["johannes@example.com"]
  spec.summary = "Named Entity Recognition for Ruby using ONNX models"
  spec.description = "NER using ONNX models via onnx-ruby and tokenizer-ruby. Extracts people, places, organizations, and other entities from text."
  spec.homepage = "https://github.com/johannesdwicahyo/ner-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "Rakefile",
    "ner-ruby.gemspec"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "onnx-ruby", "~> 0.1"
  spec.add_dependency "tokenizer-ruby", "~> 0.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
