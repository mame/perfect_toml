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
end
