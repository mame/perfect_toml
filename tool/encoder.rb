#!/usr/bin/env ruby

# usage: TOML_DECODER_VERSION=1.0 /path/to/toml-test-v2.1.0-linux-amd64 test -toml 1.0 -decoder tool/decoder.rb -encoder tool/encoder.rb
# usage: TOML_DECODER_VERSION=1.1 /path/to/toml-test-v2.1.0-linux-amd64 test -toml 1.1 -decoder tool/decoder.rb -encoder tool/encoder.rb

require_relative "../lib/perfect_toml"
require "json"
require "time"

def json_to_toml(json)
  return json.map {|v| json_to_toml(v) } if Array === json
  if json.key?("type")
    type, val = json["type"], json["value"]
    case type
    when "integer" then val.to_i
    when "float"
      case val.downcase
      when "inf", "+inf" then Float::INFINITY
      when "-inf" then -Float::INFINITY
      when "nan" then -Float::NAN
      else
        val.to_f
      end
    when "string" then val
    when "bool" then val == "true"
    when "datetime" then Time.iso8601(val)
    when "datetime-local"
      raise if val !~ /\A(-?\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)\z/
      PerfectTOML::LocalDateTime.new($1, $2, $3, $4, $5, $6)
    when "date-local"
      raise if val !~ /\A(-?\d{4})-(\d{2})-(\d{2})\z/
      PerfectTOML::LocalDate.new($1, $2, $3)
    when "time-local"
      raise if val !~ /\A(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)\z/
      PerfectTOML::LocalTime.new($1, $2, $3)
    else
      json.to_h {|k, v| [k, json_to_toml(v)] }
    end
  else
    json.to_h {|k, v| [k, json_to_toml(v)] }
  end
end

puts PerfectTOML.generate(
  json_to_toml(JSON.parse($stdin.read.force_encoding("UTF-8"))),
  use_dot: ENV["TOML_ENCODER_USE_DOT"] == "1",
  sort_keys: ENV["TOML_ENCODER_SORT_KEYS"] == "1",
  use_literal_string: ENV["TOML_ENCODER_USE_LITERAL_STRING"] == "1",
  use_multiline_string: ENV["TOML_ENCODER_USE_MULTILINE_STRING"] == "1",
)
