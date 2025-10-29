require "test_helper"

class ErrorTest < Test::Unit::TestCase
  def test_redefine_error_position
    assert_parse_error("cannot redefine `a` at line 2 column 3") do
      PerfectTOML.parse(<<-'END')
a = 1
  a = 2
      END
    end

    assert_parse_error("cannot redefine `a` at line 2 column 3") do
      PerfectTOML.parse(<<-'END')
a = 1
  [a]
      END
    end

    assert_parse_error("cannot redefine `a.b` at line 3 column 3") do
      PerfectTOML.parse(<<-'END')
[a.b]
[a]
  b = 1
      END
    end

    assert_parse_error("cannot redefine `a.b` at line 3 column 3") do
      PerfectTOML.parse(<<-'END')
[a]
b = 1
  [ a . b ]
      END
    end

    assert_parse_error("cannot redefine `a.b` at line 3 column 3") do
      PerfectTOML.parse(<<-'END')
[a]
b = 1
  [[ a . b ]]
      END
    end

    assert_parse_error("cannot redefine `b` at line 1 column 14") do
      PerfectTOML.parse(<<-'END')
a = { b = 1, b = 2 }
      END
    end
  end

  def test_wrong_character
    assert_parse_error("unexpected character found: \"\\x00\" at line 1 column 24") do
      PerfectTOML.parse(<<-END)
# control character -> \0
      END
    end

    assert_parse_error("invalid escape character in string: \"e\" at line 1 column 7") do
      PerfectTOML.parse(<<-'END')
a = "\e"
      END
    end

    assert_parse_error("invalid character in string: \"\\x00\" at line 1 column 31") do
      PerfectTOML.parse(<<-END)
a = "raw control character -> \0"
      END
    end

    assert_parse_error("invalid character in string: \"\\x00\" at line 1 column 33") do
      PerfectTOML.parse(<<-END)
a = """raw control character -> \0"""
      END
    end

    assert_parse_error("invalid character in string: \"\\x00\" at line 1 column 31") do
      PerfectTOML.parse(<<-END)
a = 'raw control character -> \0'
      END
    end

    assert_parse_error("invalid character in string: \"\\x00\" at line 1 column 33") do
      PerfectTOML.parse(<<-END)
a = '''raw control character -> \0'''
      END
    end
  end

  def test_unterminated_string
    assert_parse_error("unterminated string at line 1 column 18") do
      PerfectTOML.parse(<<-END.chomp)
a = "unterminated
      END
    end

    assert_parse_error("unterminated string at line 1 column 20") do
      PerfectTOML.parse(<<-END.chomp)
a = """unterminated
      END
    end

    assert_parse_error("unterminated string at line 1 column 18") do
      PerfectTOML.parse(<<-END.chomp)
a = 'unterminated
      END
    end

    assert_parse_error("unterminated string at line 1 column 20") do
      PerfectTOML.parse(<<-END.chomp)
a = '''unterminated
      END
    end
  end

  def test_wrong_offset_datetime
    assert_parse_error("failed to parse date or datetime \"2000-00-00T25:00:00Z\" at line 1 column 9") do
      PerfectTOML.parse(<<-'END')
wrong = 2000-00-00T25:00:00Z
      END
    end
  end

  def test_wrong_local_datetime
    assert_parse_error("failed to parse date or datetime \"2000-00-00T25:00:00\" at line 1 column 9") do
      PerfectTOML.parse(<<-'END')
wrong = 2000-00-00T25:00:00
      END
    end
  end

  def test_wrong_local_date
    assert_parse_error("failed to parse date or datetime \"2000-00-00\" at line 1 column 9") do
      PerfectTOML.parse(<<-'END')
wrong = 2000-00-00
      END
    end
  end

  def test_wrong_local_time
    assert_parse_error("failed to parse time \"25:00:00\" at line 1 column 9") do
      PerfectTOML.parse(<<-'END')
wrong = 25:00:00
      END
    end
  end
end
