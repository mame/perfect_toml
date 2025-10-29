require "test_helper"

# The parse is mainly tested in conformance_test.rb

class MiscTest < Test::Unit::TestCase
  def test_symbolize_names
    exp = { a: 1, "あ": 2, b: { c: 3 } }

    assert_equal(exp, PerfectTOML.parse(<<-END, symbolize_names: true))
a = 1
"あ" = 2
b.c = 3
    END
  end

  def test_mutiline_string_delimiter
    exp = { "a" => "str\"ing" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
a = """str"ing"""
    END

    exp = { "a" => "str\"\"ing" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
a = """str""ing"""
    END

    exp = { "a" => "string\"" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
a = """string""""
    END

    exp = { "a" => "string\"\"" }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
a = """string"""""
    END

    exp = { "a" => "string\"\"" }

    assert_parse_error("unexpected character found: \"\\\"\" at line 1 column 19") do
      PerfectTOML.parse(<<-'END')
a = """string""""""
      END
    end
  end

  def test_update_declared_table_by_value_definition
    assert_parse_error("cannot redefine `a.b` at line 4 column 3") do
      PerfectTOML.parse(<<-'END')
[a.b]
  z = 9
[a]
  b.t = 9
      END
    end
  end

  def test_unterminated_array
    assert_parse_error("unexpected end at line 1 column 11") do
      PerfectTOML.parse(<<-'END'.chomp)
a = [ 1, 2
      END
    end
  end

  def test_empty_inline_table
    exp = { "a" => {} }

    assert_equal(exp, PerfectTOML.parse(<<-'END'))
a = { }
    END
  end

  def test_unterminated_inline_table
    assert_parse_error("unexpected end at line 1 column 12") do
      PerfectTOML.parse(<<-'END'.chomp)
a = { b = 1
      END
    end
  end

  def test_toml_1_1_escaped_char_in_string
    toml = <<-'END'.chomp
a = "\e"
    END

    assert_parse_error("invalid escape character in string: \"e\" at line 1 column 7") do
      PerfectTOML.parse(toml, version: "1.0.0")
    end

    exp = { "a" => "\e" }
    assert_equal(exp, PerfectTOML.parse(toml, version: "1.1.0"))

    toml = <<-'END'.chomp
a = "\x20"
    END

    assert_parse_error("invalid escape character in string: \"x\" at line 1 column 7") do
      PerfectTOML.parse(toml, version: "1.0.0")
    end

    exp = { "a" => " " }
    assert_equal(exp, PerfectTOML.parse(toml, version: "1.1.0"))
  end

  def test_toml_1_1_omittable_seconds_in_datetime
    toml = <<-'END'.chomp
a = 2001-02-03T04:05Z
    END

    assert_parse_error("seconds field is required at line 1 column 22") do
      PerfectTOML.parse(toml, version: "1.0.0")
    end

    exp = { "a" => Time.utc(2001, 2, 3, 4, 5, 0) }
    assert_equal(exp, PerfectTOML.parse(toml, version: "1.1.0"))

    toml = <<-'END'.chomp
a = 04:05
    END

    assert_parse_error("seconds field is required at line 1 column 10") do
      PerfectTOML.parse(toml, version: "1.0.0")
    end

    exp = { "a" => PerfectTOML::LocalTime.new(4, 5, 0) }
    assert_equal(exp, PerfectTOML.parse(toml, version: "1.1.0"))
  end

  def test_toml_1_1_newline_in_inline_table
    toml = <<-'END'.chomp
foo = {
      bar
    =
  {
    baz
    =
    1
    ,
  }
,
qux # comment
  =   # comment
    2   # comment
      ,   # comment
        }
    END

    assert_parse_error("unexpected character found: \"\\n\" at line 1 column 8") do
      PerfectTOML.parse(toml, version: "1.0.0")
    end

    exp = { "foo" => { "bar" => { "baz" => 1 }, "qux" => 2 } }

    assert_equal(exp, PerfectTOML.parse(toml, version: "1.1.0"))
  end

  def test_unsupported_toml_version
    assert_raise(ArgumentError, "unsupported TOML version: \"0.5.0\"") do
      PerfectTOML.parse("", version: "0.5.0")
    end
  end
end
