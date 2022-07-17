require "test_helper"
require "pp"

class DateTimeTest < Test::Unit::TestCase
  def test_local_date_time
    d1 = PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4)

    assert_equal(Time.new(1970, 1, 1, 2, 3, 4), d1.to_time)
    assert_equal(Time.new(1970, 1, 1, 2, 3, 4, "UTC"), d1.to_time("UTC"))
    assert_equal("1970-01-01T02:03:04", d1.to_s)
    assert_equal("1970-01-01T02:03:04", d1.to_inline_toml)
    assert_equal("#<PerfectTOML::LocalDateTime 1970-01-01T02:03:04>", d1.inspect)
    assert_equal("#<PerfectTOML::LocalDateTime 1970-01-01T02:03:04>\n", d1.pretty_inspect)

    d2 = PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4.56789r)

    assert_equal(Time.new(1970, 1, 1, 2, 3, 4.56789r), d2.to_time)
    assert_equal(Time.new(1970, 1, 1, 2, 3, 4.56789r, "UTC"), d2.to_time("UTC"))
    assert_equal("1970-01-01T02:03:04.567890000", d2.to_s)
    assert_equal("1970-01-01T02:03:04.567890000", d2.to_inline_toml)
    assert_equal("#<PerfectTOML::LocalDateTime 1970-01-01T02:03:04.567890000>", d2.inspect)
    assert_equal("#<PerfectTOML::LocalDateTime 1970-01-01T02:03:04.567890000>\n", d2.pretty_inspect)

    assert_equal(0, d1 <=> d1)
    assert_equal(-1, d1 <=> d2)
  end

  def test_local_date
    d1 = PerfectTOML::LocalDate.new(1970, 1, 1)

    assert_equal(Time.new(1970, 1, 1, 0, 0, 0), d1.to_time)
    assert_equal(Time.new(1970, 1, 1, 0, 0, 0, "UTC"), d1.to_time("UTC"))
    assert_equal("1970-01-01", d1.to_s)
    assert_equal("1970-01-01", d1.to_inline_toml)
    assert_equal("#<PerfectTOML::LocalDate 1970-01-01>", d1.inspect)
    assert_equal("#<PerfectTOML::LocalDate 1970-01-01>\n", d1.pretty_inspect)

    d2 = PerfectTOML::LocalDate.new(1970, 1, 2)
    assert_equal(0, d1 <=> d1)
    assert_equal(-1, d1 <=> d2)
  end

  def test_local_time
    t1 = PerfectTOML::LocalTime.new(2, 3, 4)

    assert_equal(Time.new(1970, 1, 1, 2, 3, 4), t1.to_time(1970, 1, 1))
    assert_equal(Time.new(1970, 1, 1, 2, 3, 4, "UTC"), t1.to_time(1970, 1, 1, "UTC"))
    assert_equal("02:03:04", t1.to_s)
    assert_equal("02:03:04", t1.to_inline_toml)
    assert_equal("#<PerfectTOML::LocalTime 02:03:04>", t1.inspect)
    assert_equal("#<PerfectTOML::LocalTime 02:03:04>\n", t1.pretty_inspect)

    t2 = PerfectTOML::LocalTime.new(2, 3, 4.56789r)

    assert_equal(Time.new(1970, 1, 1, 2, 3, 4.56789r), t2.to_time(1970, 1, 1))
    assert_equal(Time.new(1970, 1, 1, 2, 3, 4.56789r, "UTC"), t2.to_time(1970, 1, 1, "UTC"))
    assert_equal("02:03:04.567890000", t2.to_s)
    assert_equal("02:03:04.567890000", t2.to_inline_toml)
    assert_equal("#<PerfectTOML::LocalTime 02:03:04.567890000>", t2.inspect)
    assert_equal("#<PerfectTOML::LocalTime 02:03:04.567890000>\n", t2.pretty_inspect)

    assert_equal(0, t1 <=> t1)
    assert_equal(-1, t1 <=> t2)
  end
end
