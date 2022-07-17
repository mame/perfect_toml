require "simplecov"
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "perfect_toml"

require "test-unit"

module Test::Unit::Assertions
  def assert_parse_error(msg, &blk)
    assert_raise(PerfectTOML::ParseError.new(msg), &blk)
  end
end
