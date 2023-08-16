# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require_relative "lib/query_police/version"

Gem::Specification.new do |spec|
  spec.name = "query_police"
  spec.version = QueryPolice::VERSION
  spec.authors = ["strikeraryu"]
  spec.email = ["striker.aryu56@gmail.com"]

  spec.summary = "This gem provides tools to analyze your queries based on custom rules and detect bad queries."
  spec.homepage = "https://github.com/strikeraryu/query_police.git"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.4.1"
  spec.required_rubygems_version = ">= 1.3.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/strikeraryu/query_police.git"
  spec.metadata["changelog_uri"] = "https://github.com/strikeraryu/query_police/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_runtime_dependency "activerecord", ">= 3.0.0", "< 8.0.0"
  spec.add_runtime_dependency "activesupport", ">= 3.0.0", "< 8.0.0"
  spec.add_runtime_dependency "colorize", ">= 0.5.0", "< 0.8.1"
  spec.add_runtime_dependency "terminal-table", ">= 3.0.0", "< 3.0.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
