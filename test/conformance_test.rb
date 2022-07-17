require "test_helper"

# https://toml.io/en/v1.0.0
class ConformanceTest < Test::Unit::TestCase
  def test_comment
    exp = { "another" => "# This is not a comment", "key" => "value" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# This is a full-line comment
key = "value"  # This is a comment at the end of a line
another = "# This is not a comment"
    END
  end

  def test_key_value
    exp = { "key" => "value" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
key = "value"
    END
  end

  def test_unspecified_value
    assert_parse_error("unexpected character found: \"#\" at line 1 column 7") do
      PerfectTOML.parse(<<-'END')
key = # INVALID
      END
    end
  end

  def test_no_newline_after_value
    assert_parse_error("unexpected identifier found: \"last\" at line 1 column 15") do
      PerfectTOML.parse(<<-'END')
first = "Tom" last = "Preston-Werner" # INVALID
      END
    end
  end

  def test_keys
    exp = {
      "key" => "value",
      "bare_key" => "value",
      "bare-key" => "value",
      "1234" => "value",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
key = "value"
bare_key = "value"
bare-key = "value"
1234 = "value"
    END
  end

  def test_quoted_keys
    exp = {
      "127.0.0.1" => "value",
      "character encoding" => "value",
      "key2" => "value",
      "quoted \"value\"" => "value",
      "ʎǝʞ" => "value",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
"127.0.0.1" = "value"
"character encoding" = "value"
"ʎǝʞ" = "value"
'key2' = "value"
'quoted "value"' = "value"
    END
  end

  def test_empty_keys
    assert_parse_error("unexpected character found: \"=\" at line 1 column 1") do
      PerfectTOML.parse(<<-'END')
= "no key name"  # INVALID
      END
    end

    exp = { "" => "blank" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
"" = "blank"     # VALID but discouraged
    END
    assert_equal(exp, PerfectTOML.parse(<<-'END'))
'' = 'blank'     # VALID but discouraged
    END
  end

  def test_dotted_keys
    exp = {
      "name" => "Orange",
      "physical" => {
        "color" => "orange",
        "shape" => "round",
      },
      "site" => {
        "google.com" => true,
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
name = "Orange"
physical.color = "orange"
physical.shape = "round"
site."google.com" = true
    END
  end

  def test_whitespace_around_dot
    exp = {
      "fruit" => {
        "name" => "banana",
        "color" => "yellow",
        "flavor" => "banana",
      }
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
fruit.name = "banana"     # this is best practice
fruit. color = "yellow"    # same as fruit.color
fruit . flavor = "banana"   # same as fruit.flavor
    END
  end

  def test_duplicated_keys
    assert_parse_error("cannot redefine `name` at line 3 column 1") do
      PerfectTOML.parse(<<-'END')
# DO NOT DO THIS
name = "Tom"
name = "Pradyun"
      END
    end
  end

  def test_duplicated_keys_with_quote
    assert_parse_error("cannot redefine `spelling` at line 3 column 1") do
      PerfectTOML.parse(<<-'END')
# THIS WILL NOT WORK
spelling = "favorite"
"spelling" = "favourite"
      END
    end
  end

  def test_parallel_dotted_keys
    exp = {
      "fruit" => {
        "apple" => {
          "smooth" => true,
        },
        "orange" => 2,
      }
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# This makes the key "fruit" into a table.
fruit.apple.smooth = true

# So then you can add to the table "fruit" like so:
fruit.orange = 2
    END
  end

  def test_inconsistent_dotted_keys
    assert_parse_error("cannot redefine `fruit.apple` at line 8 column 1") do
      PerfectTOML.parse(<<-'END')
# THE FOLLOWING IS INVALID

# This defines the value of fruit.apple to be an integer.
fruit.apple = 1

# But then this treats fruit.apple like it's a table.
# You can't turn an integer into a table.
fruit.apple.smooth = true
      END
    end
  end

  def test_dotted_keys_out_of_order
    exp = {
      "apple" => {
        "type" => "fruit",
        "skin" => "thin",
        "color" => "red",
      },
      "orange" => {
        "type" => "fruit",
        "skin" => "thick",
        "color" => "orange",
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# VALID BUT DISCOURAGED

apple.type = "fruit"
orange.type = "fruit"

apple.skin = "thin"
orange.skin = "thick"

apple.color = "red"
orange.color = "orange"
    END
  end

  def test_pi
    exp = { "3" => { "14159" => "pi" } }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
3.14159 = "pi"
    END
  end

  def test_basic_string
    exp = { "str" => "I'm a string. \"You can quote me\". Name\tJos\u00E9\nLocation\tSF." }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
str = "I'm a string. \"You can quote me\". Name\tJos\u00E9\nLocation\tSF."
    END
  end

  def test_multiline_basic_strings
    exp = {
      "str1" => "Roses are red\nViolets are blue",
      "str2" => "Roses are red\nViolets are blue",
      "str3" => "Roses are red\r\nViolets are blue",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
str1 = """
Roses are red
Violets are blue"""

# On a Unix system, the above multi-line string will most likely be the same as:
str2 = "Roses are red\nViolets are blue"

# On a Windows system, it will most likely be equivalent to:
str3 = "Roses are red\r\nViolets are blue"
    END
  end

  def test_line_ending_backslask_in_multiline_basic_string
    exp = {
      "str1" => "The quick brown fox jumps over the lazy dog.",
      "str2" => "The quick brown fox jumps over the lazy dog.",
      "str3" => "The quick brown fox jumps over the lazy dog.",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# The following strings are byte-for-byte equivalent:
str1 = "The quick brown fox jumps over the lazy dog."

str2 = """
The quick brown \


  fox jumps over \
    the lazy dog."""

str3 = """\
       The quick brown \
       fox jumps over \
       the lazy dog.\
       """
    END
  end

  def test_quotation_marks_in_multiline_basic_string
    exp = {
      "str4" => 'Here are two quotation marks: "". Simple enough.',
      "str5" => 'Here are three quotation marks: """.',
      "str6" => 'Here are fifteen quotation marks: """"""""""""""".',
      "str7" => '"This," she said, "is just a pointless statement."',
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
str4 = """Here are two quotation marks: "". Simple enough."""
# str5 = """Here are three quotation marks: """."""  # INVALID
str5 = """Here are three quotation marks: ""\"."""
str6 = """Here are fifteen quotation marks: ""\"""\"""\"""\"""\"."""

# "This," she said, "is just a pointless statement."
str7 = """"This," she said, "is just a pointless statement.""""
    END

    assert_parse_error("unexpected character found: \".\" at line 1 column 46") do
      PerfectTOML.parse(<<-END)
str5 = """Here are three quotation marks: """."""  # INVALID
      END
    end
  end

  def test_literal_strings
    exp = {
      "winpath" =>  'C:\\Users\\nodejs\\templates',
      "winpath2" => '\\\\ServerX\\admin$\\system32\\',
      "quoted" => 'Tom "Dubs" Preston-Werner',
      "regex" => '<\\i\\c*\\s*>',
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# What you see is what you get.
winpath  = 'C:\Users\nodejs\templates'
winpath2 = '\\ServerX\admin$\system32\'
quoted   = 'Tom "Dubs" Preston-Werner'
regex    = '<\i\c*\s*>'
    END
  end

  def test_multiline_literal_strings
    exp = {
      "regex2" => 'I [dw]on\'t need \\d{2} apples',
      "lines" => "The first newline is\ntrimmed in raw strings.\n   All other whitespace\n   is preserved.\n",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
regex2 = '''I [dw]on't need \d{2} apples'''
lines  = '''
The first newline is
trimmed in raw strings.
   All other whitespace
   is preserved.
'''
    END
  end

  def test_quotation_marks_in_multiline_literal_string
    exp = {
      "quot15" => 'Here are fifteen quotation marks: """""""""""""""',
      "apos15" => "Here are fifteen apostrophes: '''''''''''''''",
      "str" => "'That,' she said, 'is still pointless.'",
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
quot15 = '''Here are fifteen quotation marks: """""""""""""""'''

# apos15 = '''Here are fifteen apostrophes: ''''''''''''''''''  # INVALID
apos15 = "Here are fifteen apostrophes: '''''''''''''''"

# 'That,' she said, 'is still pointless.'
str = ''''That,' she said, 'is still pointless.''''
    END

    assert_parse_error("unexpected character found: \"'\" at line 1 column 48") do
      PerfectTOML.parse(<<-END)
apos15 = '''Here are fifteen apostrophes: ''''''''''''''''''  # INVALID
      END
    end
  end

  def test_integer
    exp = { "int1" => 99, "int2" => 42, "int3" => 0, "int4" => -17 }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
int1 = +99
int2 = 42
int3 = 0
int4 = -17
    END
  end

  def test_integer_with_underscore
    exp = { "int5" => 1000, "int6" => 5349221, "int7" => 5349221, "int8" => 12345 }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
int5 = 1_000
int6 = 5_349_221
int7 = 53_49_221  # Indian number system grouping
int8 = 1_2_3_4_5  # VALID but discouraged
    END
  end

  def test_integer_with_prefix
    exp = {
      "hex1" => 0xdeadbeef,
      "hex2" => 0xdeadbeef,
      "hex3" => 0xdeadbeef,
      "oct1" => 0o01234567,
      "oct2" => 0o755,
      "bin1" => 0b11010110,
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# hexadecimal with prefix `0x`
hex1 = 0xDEADBEEF
hex2 = 0xdeadbeef
hex3 = 0xdead_beef

# octal with prefix `0o`
oct1 = 0o01234567
oct2 = 0o755 # useful for Unix file permissions

# binary with prefix `0b`
bin1 = 0b11010110
    END
  end

  def test_float
    exp = {
      "flt1" => +1.0,
      "flt2" => 3.1415,
      "flt3" => -0.01,
      "flt4" => 5e+22,
      "flt5" => 1e06,
      "flt6" => -2E-2,
      "flt7" => 6.626e-34,
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# fractional
flt1 = +1.0
flt2 = 3.1415
flt3 = -0.01

# exponent
flt4 = 5e+22
flt5 = 1e06
flt6 = -2E-2

# both
flt7 = 6.626e-34
    END
  end

  def test_invalid_float
    assert_parse_error("unexpected character found: \".\" at line 2 column 19") do
      PerfectTOML.parse(<<-END)
# INVALID FLOATS
invalid_float_1 = .7
      END
    end

    assert_parse_error("unexpected character found: \".\" at line 1 column 20") do
      PerfectTOML.parse(<<-END)
invalid_float_2 = 7.
      END
    end

    assert_parse_error("unexpected character found: \".\" at line 1 column 20") do
      PerfectTOML.parse(<<-END)
invalid_float_3 = 3.e+20
      END
    end
  end

  def test_float_with_underscore
    exp = { "flt8" => 224617.445991228 }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
flt8 = 224_617.445_991_228
    END
  end

  def test_inf_and_nan
    toml = PerfectTOML.parse(<<-'END')
# infinity
sf1 = inf  # positive infinity
sf2 = +inf # positive infinity
sf3 = -inf # negative infinity

# not a number
sf4 = nan  # actual sNaN/qNaN encoding is implementation-specific
sf5 = +nan # same as `nan`
sf6 = -nan # valid, actual encoding is implementation-specific
    END

    assert(toml["sf1"].infinite?)
    assert(toml["sf1"] > 0)
    assert(toml["sf2"].infinite?)
    assert(toml["sf2"] > 0)
    assert(toml["sf3"].infinite?)
    assert(toml["sf3"] < 0)
    assert(toml["sf4"].nan?)
    assert(toml["sf5"].nan?)
    assert(toml["sf6"].nan?)
  end

  def test_boolean
    exp = { "bool1" => true, "bool2" => false }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
bool1 = true
bool2 = false
    END
  end

  def test_offset_datetime
    exp = {
      "odt1" => Time.new(1979, 5, 27, 7, 32, 0, "UTC"),
      "odt2" => Time.new(1979, 5, 27, 0, 32, 0, "-07:00"),
      "odt3" => Time.new(1979, 5, 27, 0, 32, 0.999999r, "-07:00"),
      "odt4" => Time.new(1979, 5, 27, 0, 32, 0, "-07:00"),
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
odt1 = 1979-05-27T07:32:00Z
odt2 = 1979-05-27T00:32:00-07:00
odt3 = 1979-05-27T00:32:00.999999-07:00
odt4 = 1979-05-27 07:32:00Z
    END
  end

  def test_local_datetime
    exp = {
      "ldt1" => PerfectTOML::LocalDateTime.new(1979, 5, 27, 7, 32, 0),
      "ldt2" => PerfectTOML::LocalDateTime.new(1979, 5, 27, 0, 32, 0.999999r),
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
ldt1 = 1979-05-27T07:32:00
ldt2 = 1979-05-27T00:32:00.999999
    END
  end

  def test_local_date
    exp = { "ld1" => PerfectTOML::LocalDate.new(1979, 5, 27) }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
ld1 = 1979-05-27
    END
  end

  def test_local_time
    exp = {
      "lt1" => PerfectTOML::LocalTime.new(7, 32, 0),
      "lt2" => PerfectTOML::LocalTime.new(0, 32, 0.999999r),
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
lt1 = 07:32:00
lt2 = 00:32:00.999999
    END
  end

  def test_array
    exp = {
      "colors" => ["red", "yellow", "green"],
      "contributors" => [
        "Foo Bar <foo@example.com>",
        {
          "email" => "bazqux@example.com",
          "name" => "Baz Qux",
          "url" => "https://example.com/bazqux",
        },
      ],
      "integers" => [1, 2, 3],
      "nested_arrays_of_ints" => [[1, 2], [3, 4, 5]],
      "nested_mixed_array" => [[1, 2], ["a", "b", "c"]],
      "numbers" => [0.1, 0.2, 0.5, 1, 2, 5],
      "string_array" => ["all", "strings", "are the same", "type"],
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
integers = [ 1, 2, 3 ]
colors = [ "red", "yellow", "green" ]
nested_arrays_of_ints = [ [ 1, 2 ], [3, 4, 5] ]
nested_mixed_array = [ [ 1, 2 ], ["a", "b", "c"] ]
string_array = [ "all", 'strings', """are the same""", '''type''' ]

# Mixed-type arrays are allowed
numbers = [ 0.1, 0.2, 0.5, 1, 2, 5 ]
contributors = [
  "Foo Bar <foo@example.com>",
  { name = "Baz Qux", email = "bazqux@example.com", url = "https://example.com/bazqux" }
]
    END
  end

  def test_table
    exp = { "table" => {} }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[table]
    END

    exp = {
      "table-1" => {
        "key1" => "some string",
        "key2" => 123,
      },
      "table-2" => {
        "key1" => "another string",
        "key2" => 456,
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[table-1]
key1 = "some string"
key2 = 123

[table-2]
key1 = "another string"
key2 = 456
    END
  end

  def test_table_with_dotted_key
    exp = { "dog" => { "tater.man" => { "type" => { "name" => "pug" } } } }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[dog."tater.man"]
type.name = "pug"
    END

    exp = {
      "a" => { "b" => { "c" => {} } },
      "d" => { "e" => { "f" => {} } },
      "g" => { "h" => { "i" => {} } },
      "j" => { "ʞ" => { "l" => {} } },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[a.b.c]            # this is best practice
[ d.e.f ]          # same as [d.e.f]
[ g .  h  . i ]    # same as [g.h.i]
[ j . "ʞ" . 'l' ]  # same as [j."ʞ".'l']
    END
  end

  def test_define_super_tables
    exp = {
      "x" => { "y" => { "z" => { "w" => {} } } },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# [x] you
# [x.y] don't
# [x.y.z] need these
[x.y.z.w] # for this to work

[x] # defining a super-table afterward is ok
    END
  end

  def test_redefine_table_directly
    assert_parse_error("cannot redefine `fruit` at line 6 column 1") do
      PerfectTOML.parse(<<-END)
# DO NOT DO THIS

[fruit]
apple = "red"

[fruit]
orange = "orange"
      END
    end
  end

  def test_redefine_table_indirectly
    assert_parse_error("cannot redefine `fruit.apple` at line 6 column 1") do
      PerfectTOML.parse(<<-END)
# DO NOT DO THIS EITHER

[fruit]
apple = "red"

[fruit.apple]
texture = "smooth"
      END
    end
  end

  def test_tables_out_of_order
    exp = {
      "fruit" => {
        "apple" => {},
        "orange" => {},
      },
      "animal" => {},
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# VALID BUT DISCOURAGED
[fruit.apple]
[animal]
[fruit.orange]
    END
  end

  def test_top_level_table
    exp = {
      "name" => "Fido",
      "breed" => "pug",
      "owner" => {
        "name" => "Regina Dogman",
        "member_since" => PerfectTOML::LocalDate.new(1999, 8, 4),
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
# Top-level table begins.
name = "Fido"
breed = "pug"

# Top-level table ends.
[owner]
name = "Regina Dogman"
member_since = 1999-08-04
    END
  end

  def test_define_tables_by_dotted_keys
    exp = {
      "fruit" => {
        "apple" => {
          "color" => "red",
          "taste" => {
            "sweet" => true,
          },
        },
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
fruit.apple.color = "red"
# Defines a table named fruit
# Defines a table named fruit.apple

fruit.apple.taste.sweet = true
# Defines a table named fruit.apple.taste
# fruit and fruit.apple were already created
    END
  end

  def test_redefine_tables_by_header
    exp = {
      "fruit" => {
        "apple" => {
          "color" => "red",
          "taste" => {
            "sweet" => true,
          },
          "texture" => {
            "smooth" => true,
          },
        },
      },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[fruit]
apple.color = "red"
apple.taste.sweet = true

# [fruit.apple]  # INVALID
# [fruit.apple.taste]  # INVALID

[fruit.apple.texture]  # you can add sub-tables
smooth = true
    END

    assert_parse_error("cannot redefine `fruit.apple` at line 5 column 1") do
      PerfectTOML.parse(<<-END)
[fruit]
apple.color = "red"
apple.taste.sweet = true

[fruit.apple]  # INVALID
# [fruit.apple.taste]  # INVALID
      END
    end

    assert_parse_error("cannot redefine `fruit.apple.taste` at line 5 column 1") do
      PerfectTOML.parse(<<-END)
[fruit]
apple.color = "red"
apple.taste.sweet = true

[fruit.apple.taste]  # INVALID
      END
    end
  end

  def test_inline_table
    exp = {
      "name" => { "first" => "Tom", "last" => "Preston-Werner" },
      "point" => { "x" => 1, "y" => 2 },
      "animal" => { "type" => { "name" => "pug" } },
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
name = { first = "Tom", last = "Preston-Werner" }
point = { x = 1, y = 2 }
animal = { type.name = "pug" }
    END

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[name]
first = "Tom"
last = "Preston-Werner"

[point]
x = 1
y = 2

[animal]
type.name = "pug"
    END
  end

  def test_redeine_inline_table
    assert_parse_error("cannot redefine `product.type` at line 3 column 1") do
      PerfectTOML.parse(<<-END)
[product]
type = { name = "Nail" }
type.edible = false  # INVALID
      END
    end
  end

  def test_redeine_table_by_inline_table
    assert_parse_error("cannot redefine `product.type` at line 3 column 1") do
      PerfectTOML.parse(<<-END)
[product]
type.name = "Nail"
type = { edible = false }  # INVALID
      END
    end
  end

  def test_array_of_tables
    exp = {
      "products" => [
        { "name" => "Hammer", "sku" => 738594937 },
        { },
        { "name" => "Nail", "sku" => 284758393, "color" => "gray" }
      ]
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[[products]]
name = "Hammer"
sku = 738594937

[[products]]  # empty table within the array

[[products]]
name = "Nail"
sku = 284758393

color = "gray"
    END
  end

  def test_subtable_in_array_of_tables
    exp = {
      "fruits"=> [
        {
          "name" => "apple",
          "physical" => { "color" => "red", "shape" => "round" },
          "varieties" => [{ "name" => "red delicious" }, { "name" => "granny smith" }],
        },
        {
          "name" => "banana",
          "varieties" => [{"name"=>"plantain"}],
        },
      ]
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
[[fruits]]
name = "apple"

[fruits.physical]  # subtable
color = "red"
shape = "round"

[[fruits.varieties]]  # nested array of tables
name = "red delicious"

[[fruits.varieties]]
name = "granny smith"


[[fruits]]
name = "banana"

[[fruits.varieties]]
name = "plantain"
    END
  end

  def test_array_of_tables_after_defined
    assert_parse_error("cannot redefine `fruit` at line 6 column 1") do
      PerfectTOML.parse(<<-END)
# INVALID TOML DOC
[fruit.physical]  # subtable, but to which parent element should it belong?
color = "red"
shape = "round"

[[fruit]]  # parser must throw an error upon discovering that "fruit" is
           # an array rather than a table
name = "apple"
      END
    end
  end

  def test_redefine_inline_array_by_header
    assert_parse_error("cannot redefine `fruits` at line 4 column 1") do
      PerfectTOML.parse(<<-END)
# INVALID TOML DOC
fruits = []

[[fruits]] # Not allowed
      END
    end
  end

  def test_redefine_type_by_header
    assert_parse_error("cannot redefine `fruits.varieties` at line 9 column 1") do
      PerfectTOML.parse(<<-END)
# INVALID TOML DOC
[[fruits]]
name = "apple"

[[fruits.varieties]]
name = "red delicious"

# INVALID: This table conflicts with the previous array of tables
[fruits.varieties]
name = "granny smith"
      END
    end

    assert_parse_error("cannot redefine `fruits.physical` at line 10 column 1") do
      PerfectTOML.parse(<<-END)
# INVALID TOML DOC
[[fruits]]
name = "apple"

[fruits.physical]
color = "red"
shape = "round"

# INVALID: This array of tables conflicts with the previous table
[[fruits.physical]]
color = "green"
      END
    end
  end

  def test_inline_table2
    exp = {
      "points" => [
        { "x" => 1, "y" => 2, "z" => 3 },
        { "x" => 7, "y" => 8, "z" => 9 },
        { "x" => 2, "y" => 4, "z" => 8 },
      ]
    }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
points = [ { x = 1, y = 2, z = 3 },
           { x = 7, y = 8, z = 9 },
           { x = 2, y = 4, z = 8 } ]
    END
  end
end
