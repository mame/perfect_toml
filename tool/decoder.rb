#!/usr/bin/env ruby

# usage: TOML_DECODER_VERSION=1.0 /path/to/toml-test-v2.1.0-linux-amd64 test -toml 1.0 -decoder tool/decoder.rb
# usage: TOML_DECODER_VERSION=1.1 /path/to/toml-test-v2.1.0-linux-amd64 test -toml 1.1 -decoder tool/decoder.rb

require_relative "../lib/perfect_toml"
require "json"

def toml_to_json(toml)
  case toml
  when Hash then toml.to_h {|k, v| [k, toml_to_json(v)] }
  when Array then toml.map {|v| toml_to_json(v) }
  when String then { "type" => "string", "value" => toml }
  when Integer then { "type" => "integer", "value" => toml.to_s }
  when Float
    str = toml.nan? ? "nan" : toml.infinite? ? "#{ toml > 0 ? "+" : "-" }inf" : toml.to_s
    str = str.sub(/\.0\z/, "")
    { "type" => "float", "value" => str }
  when true then { "type" => "bool", "value" => "true" }
  when false then { "type" => "bool", "value" => "false" }
  when Time
    str = toml.strftime("%Y-%m-%dT%H:%M:%S.%4N")
    str = str.sub(/\.0000\z/, "")
    zone = toml.strftime("%:z")
    str << (zone == "+00:00" ? "Z" : zone)
    { "type" => "datetime", "value" => str }
  when PerfectTOML::LocalDateTime
    { "type" => "datetime-local", "value" => toml.to_s }
  when PerfectTOML::LocalDate
    { "type" => "date-local", "value" => toml.to_s }
  when PerfectTOML::LocalTime
    { "type" => "time-local", "value" => toml.to_s }
  else
    raise "unknown type: %p" % toml
  end
end

puts JSON.generate(toml_to_json(PerfectTOML.parse(
  $stdin.read.force_encoding("UTF-8"),
  version: ENV.fetch("TOML_DECODER_VERSION", "1.0.0")
)))
