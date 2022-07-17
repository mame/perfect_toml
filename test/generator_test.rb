require "test_helper"

class GeneratorTest < Test::Unit::TestCase
  def test_generate_table
    exp = <<-'END'
foo = 1
    END
    assert_equal(exp, PerfectTOML.generate({ "foo" => 1 }))
    assert_equal(exp, PerfectTOML.generate({ :foo => 1 }))

    assert_equal(<<-'END', PerfectTOML.generate({ "foo" => { "bar" => 1 } }))
[foo]
bar = 1
    END
  end

  def test_generate_array
    assert_equal(<<-'END', PerfectTOML.generate({ foo: [{ a: 1 }, { b: 2 }, { c: 3 }] }))
[[foo]]
a = 1

[[foo]]
b = 2

[[foo]]
c = 3
    END

    assert_equal(<<-'END', PerfectTOML.generate({ foo: { bar: [{}, {}, {}] } }))
[[foo.bar]]

[[foo.bar]]

[[foo.bar]]
    END
  end

  def test_quoted_key
    assert_equal(<<-'END', PerfectTOML.generate({ a: { あ: { b: { い: 1 } } } }))
[a."あ".b]
"い" = 1
    END
  end

  def test_boolean
    assert_equal(<<-'END', PerfectTOML.generate({ a: true }))
a = true
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: false }))
a = false
    END
  end

  def test_float
    data = { a: 1.0, b: Float::INFINITY, c: -Float::INFINITY, d: Float::NAN }
    assert_equal(<<-'END', PerfectTOML.generate(data))
a = 1.0
b = inf
c = -inf
d = nan
    END
  end

  def test_time
    data = {
      a: Time.new(1970, 1, 1, 2, 3, 4, "UTC"),
      b: Time.new(1970, 1, 1, 2, 3, 4, "+00:00"),
      c: Time.new(1970, 1, 1, 2, 3, 4.56789, "UTC"),
    }
    assert_equal(<<-'END', PerfectTOML.generate(data))
a = 1970-01-01T02:03:04Z
b = 1970-01-01T02:03:04+00:00
c = 1970-01-01T02:03:04.567890000Z
    END
  end

  def test_local_datetime
    data = {
      a: PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4),
      b: PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4.56789),
    }
    assert_equal(<<-'END', PerfectTOML.generate(data))
a = 1970-01-01T02:03:04
b = 1970-01-01T02:03:04.567890000
    END
  end

  def test_local_date
    data = {
      a: PerfectTOML::LocalDate.new(1970, 1, 1),
    }
    assert_equal(<<-'END', PerfectTOML.generate(data))
a = 1970-01-01
    END
  end

  def test_local_time
    data = {
      a: PerfectTOML::LocalTime.new(2, 3, 4),
      b: PerfectTOML::LocalTime.new(2, 3, 4.56789),
    }
    assert_equal(<<-'END', PerfectTOML.generate(data))
a = 02:03:04
b = 02:03:04.567890000
    END
  end

  def test_string
    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo" }))
a = "foo"
    END

    assert_equal(<<-'END'.sub("[TAB]", "\t"), PerfectTOML.generate({ a: "foo\bbar\tbaz\nqux\fquux\rend" }))
a = "foo\bbar[TAB]baz\nqux\fquux\rend"
    END

    assert_equal(<<-'END'.sub("[TAB]", "\t"), PerfectTOML.generate({ a: "foo\x00bar\x7fbaz" }))
a = "foo\u0000bar\u007fbaz"
    END
  end

  def test_inline_array
    assert_equal(<<-'END', PerfectTOML.generate({ a: [[1, 2, 3], [4, 5, 6]] }))
a = [[1, 2, 3], [4, 5, 6]]
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: [{}, 1] }))
a = [{}, 1]
    END
  end

  def test_inline_table
    assert_equal(<<-'END', PerfectTOML.generate({ a: [{ b: { c: 42 } }, 1] }))
a = [{ b = { c = 42 } }, 1]
    END
  end

  def test_sort_keys
    assert_equal(<<-'END', PerfectTOML.generate({ z: 1, a: 2 }, sort_keys: false))
z = 1
a = 2
    END

    assert_equal(<<-'END', PerfectTOML.generate({ z: 1, a: 2 }, sort_keys: true))
a = 2
z = 1
    END
  end

  def test_use_literal_string
    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\"bar", b: "baz'qux" }, use_literal_string: false))
a = "foo\"bar"
b = "baz'qux"
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\"bar", b: "baz'qux" }, use_literal_string: true))
a = 'foo"bar'
b = "baz'qux"
    END
  end

  def test_use_multiline_string
    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"baz" }, use_multiline_string: true))
a = """
foo
bar"baz"""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"\"baz" }, use_multiline_string: true))
a = """
foo
bar""baz"""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"\"\"baz" }, use_multiline_string: true))
a = """
foo
bar\"""baz"""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"" }, use_multiline_string: true))
a = """
foo
bar""""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"\"" }, use_multiline_string: true))
a = """
foo
bar"""""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar\"\"\"" }, use_multiline_string: true))
a = """
foo
bar\""""""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "\n" }, use_multiline_string: true))
a = """

"""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "\nfoo\x00bar" }, use_multiline_string: true))
a = """

foo\u0000bar"""
    END
  end

  def test_use_multiline_string_with_literal_string
    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar" }, use_literal_string: false, use_multiline_string: false))
a = "foo\nbar"
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar" }, use_literal_string: false, use_multiline_string: true))
a = """
foo
bar"""
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar" }, use_literal_string: true, use_multiline_string: false))
a = "foo\nbar"
    END

    assert_equal(<<-'END', PerfectTOML.generate({ a: "foo\nbar" }, use_literal_string: true, use_multiline_string: true))
a = '''
foo
bar'''
    END
  end

  def test_use_dot
    assert_equal(<<-'END', PerfectTOML.generate({ foo: { bar: 1 } }, use_dot: true))
foo.bar = 1
    END

    assert_equal(<<-'END', PerfectTOML.generate({ foo: { bar: { baz: { qux: 1 } } } }, use_dot: true))
foo.bar.baz.qux = 1
    END

    data = {
      "foo" => {
        "bar" => { "baz" => 1 },
        "qux" => 2,
      }
    }
    assert_equal(<<-'END', PerfectTOML.generate(data, use_dot: true))
[foo]
bar.baz = 1
qux = 2
    END
  end

  def test_dup_check
    assert_raise(ArgumentError) do
      PerfectTOML.generate({ "foo" => 1, :foo => 2 })
    end
  end
end
