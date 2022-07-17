# frozen_string_literal: true

require_relative "lib/perfect_toml"

Gem::Specification.new do |spec|
  spec.name = "perfect_toml"
  spec.version = PerfectTOML::VERSION
  spec.authors = ["Yusuke Endoh"]
  spec.email = ["mame@ruby-lang.org"]

  spec.summary = "A fast TOML parser gem fully compliant with TOML v1.0.0"
  spec.description = <<END
PerfectTOML is yet another TOML parser.
It is fully compliant with TOML v1.0.0, and faster than existing TOML parsers for Ruby.
END
  spec.homepage = "https://github.com/mame/perfect_toml"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mame/perfect_toml"
  spec.metadata["changelog_uri"] = "https://github.com/mame/perfect_toml/blob/main/CHANGELOG.md"

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
end
