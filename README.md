# PerfectTOML

Yet another [TOML](https://github.com/toml-lang/toml) parser and generator.

Features:

* Fully compliant with [TOML v1.0.0](https://toml.io/en/v1.0.0). It passes [BurntSushi/toml-test](https://github.com/BurntSushi/toml-test).
* Faster than existing TOML parsers for Ruby. See [Benchmark](#benchmark).
* Single-file, plain old Ruby script without any dependencies: [perfect_toml.rb](https://github.com/mame/perfect_toml/blob/master/lib/perfect_toml.rb).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add perfect_toml

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install perfect_toml

## Parser Usage

```ruby
require "perfect_toml"

# Decodes a TOML string
p PerfectTOML.parse("key = 42") #=> { "key" => 42 }

# Load a TOML file
PerfectTOML.load_file("file.toml")

# If you want Symbol keys:
PerfectTOML.load_file("file.toml", symbolize_names: true)
```

## Generator Usage

```ruby
require "perfect_toml"

# Encode a Hash in TOML format
p PerfectTOML.generate({ key: 42 }) #=> "key = 42\n"

# Save a Hash in a TOML file
PerfectTOML.save_file("file.toml", { key: 42 })
```

See the document for options.

## TOML's value vs. Ruby's value

TOML's table is converted to Ruby's Hash, and vice versa.
Other most TOML values are converted to an object of Ruby class of the same name:
for example, TOML's String corresponds to Ruby's String.
Because there are no classes corresponding to TOML's Local Date-Time, Local Date, and Local Time,
PerfectTOML provides dedicated classes, respectively,
`PerfectTOML::LocalDateTime`, `PerfectTOML::LocalDate`, and `PerfectTOML::LocalTime`.

```ruby
require "perfect_toml"

p PerfectTOML.parse("local-date = 1970-01-01)
#=> { "local-date" => #<PerfectTOML::LocalDate 1970-01-01> }
```

## Benchmark

PerfectTOML is 5x faster than [tomlrb](https://github.com/fbernier/tomlrb), and 100x faster than [toml-rb](https://github.com/emancu/toml-rb).

```ruby
require "benchmark/ips"
require_relative "lib/perfect_toml"
require "toml-rb"
require "tomlrb"

# https://raw.githubusercontent.com/toml-lang/toml/v0.5.0/examples/example-v0.4.0.toml
toml = File.read("example-v0.4.0.toml")

Benchmark.ips do |x|
  x.report("emancu/toml-rb")     { TomlRB.parse(data) }
  x.report("fbernier/tomlrb")    { Tomlrb.parse(data) }
  x.report("mame/perfect_toml")  { PerfectTOML.parse(data) }
  x.compare!
end
```

```
...
Comparison:
   mame/perfect_toml:     2982.5 i/s
     fbernier/tomlrb:      515.7 i/s - 5.78x  (± 0.00) slower
      emancu/toml-rb:       25.4 i/s - 117.36x  (± 0.00) slower
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mame/perfect_toml.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
