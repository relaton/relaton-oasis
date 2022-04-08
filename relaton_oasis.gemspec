# frozen_string_literal: true

require_relative "lib/relaton_oasis/version"

Gem::Specification.new do |spec|
  spec.name          = "relaton-oasis"
  spec.version       = RelatonOasis::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "RelatonOasis: retrieve OASIS Standards for bibliographic use "\
                       "using the BibliographicItem model"
  spec.description   = "RelatonOasis: retrieve OASIS Standards for bibliographic use "\
                       "using the BibliographicItem model"
  spec.homepage      = "https://github.com/metanorma/relaton-oasis"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.5.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "ruby-jing"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "vcr", "~> 5.0.0"
  spec.add_development_dependency "webmock"

  spec.add_dependency "mechanize"
  spec.add_dependency "relaton-bib", "~> 1.11.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
