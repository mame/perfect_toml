#!/usr/bin/env ruby

require_relative "../lib/perfect_toml"
require "json"

def convert(toml)
  case toml
  when Hash then toml.to_h {|k, v| [k, convert(v)] }
  when Array then toml.map {|v| convert(v) }
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

puts JSON.generate(convert(PerfectTOML.parse($stdin.read)))
