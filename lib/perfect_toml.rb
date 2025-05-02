# MIT License
# 
# Copyright (c) 2022 Yusuke Endoh
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require "strscan"

module PerfectTOML
  VERSION = "0.9.0"

  class LocalDateTimeBase
    def to_inline_toml
      to_s
    end

    def inspect
      "#<#{ self.class } #{ to_s }>"
    end

    def pretty_print(q)
      q.text inspect
    end

    def ==(other)
      self.class == other.class &&
        [:year, :month, :day, :hour, :min, :sec].all? do |key|
          !respond_to?(key) || (send(key) == other.send(key))
        end
    end

    include Comparable

    def <=>(other)
      return nil if self.class != other.class
      [:year, :month, :day, :hour, :min, :sec].each do |key|
        next unless respond_to?(key)
        cmp = send(key) <=> other.send(key)
        return cmp if cmp != 0
      end
      return 0
    end
  end

  # Represents TOML's Local Date-Time
  #
  # See https://toml.io/en/v1.0.0#local-date-time
  class LocalDateTime < LocalDateTimeBase
    def initialize(year, month, day, hour, min, sec)
      @year = year.to_i
      @month = month.to_i
      @day = day.to_i
      @hour = hour.to_i
      @min = min.to_i
      @sec = Numeric === sec ? sec : sec.include?(".") ? Rational(sec) : sec.to_i
    end

    attr_reader :year, :month, :day, :hour, :min, :sec

    # Converts to a Time object with the local timezone.
    #
    #   ldt = PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4)
    #   ldt.to_time #=> 1970-01-01 02:03:04 +0900
    #
    # You can specify timezone by passing an argument.
    #
    #   ldt.to_time("UTC")    #=> 1970-01-01 02:03:04 UTC
    #   ldt.to_time("+00:00") #=> 1970-01-01 02:03:04 +0000
    def to_time(zone = nil)
      @time = Time.new(@year, @month, @day, @hour, @min, @sec, zone)
    end

    # Returns a string representation in RFC 3339 format
    #
    #   ldt = PerfectTOML::LocalDateTime.new(1970, 1, 1, 2, 3, 4)
    #   ldt.to_s #=> 1970-01-01T02:03:04
    def to_s
      s = "%04d-%02d-%02dT%02d:%02d:%02d" % [@year, @month, @day, @hour, @min, @sec]
      s << ("%11.9f" % (@sec - @sec.floor))[1..] unless Integer === @sec
      s
    end
  end

  # Represents TOML's Local Date
  #
  # See https://toml.io/en/v1.0.0#local-date
  class LocalDate < LocalDateTimeBase
    def initialize(year, month, day)
      @year = year.to_i
      @month = month.to_i
      @day = day.to_i
    end

    attr_reader :year, :month, :day

    # Converts to a Time object with the local timezone.
    # Its time will be 00:00:00.
    #
    #   ld = PerfectTOML::LocalDate.new(1970, 1, 1)
    #   ld.to_time #=> 1970-01-01 00:00:00 +0900
    #
    # You can specify timezone by passing an argument.
    #
    #   ld.to_time("UTC")    #=> 1970-01-01 00:00:00 UTC
    #   ld.to_time("+00:00") #=> 1970-01-01 00:00:00 +0000
    def to_time(zone = nil)
      Time.new(@year, @month, @day, 0, 0, 0, zone)
    end

    # Returns a string representation in RFC 3339 format
    #
    #   ld = PerfectTOML::LocalDate.new(1970, 1, 1)
    #   ld.to_s #=> 1970-01-01
    def to_s
      "%04d-%02d-%02d" % [@year, @month, @day]
    end
  end


  # Represents TOML's Local Time
  #
  # See https://toml.io/en/v1.0.0#local-time
  class LocalTime < LocalDateTimeBase
    def initialize(hour, min, sec)
      @hour = hour.to_i
      @min = min.to_i
      @sec = Numeric === sec ? sec : sec.include?(".") ? Rational(sec) : sec.to_i
    end

    attr_reader :hour, :min, :sec

    # Converts to a Time object with the local timezone.
    # You need to specify year, month, and day.
    #
    #   ld = PerfectTOML::LocalTime.new(2, 3, 4)
    #   ld.to_time(1970, 1, 1) #=> 1970-01-01 02:03:04 +0900
    #
    # You can specify timezone by passing the fourth argument.
    #
    #   ld.to_time(1970, 1, 1, "UTC")    #=> 1970-01-01 02:03:04 UTC
    #   ld.to_time(1970, 1, 1, "+00:00") #=> 1970-01-01 02:03:04 +0000
    def to_time(year, month, day, zone = nil)
      Time.new(year, month, day, @hour, @min, @sec, zone)
    end

    # Returns a string representation in RFC 3339 format
    #
    #   lt = PerfectTOML::LocalTime.new(2, 3, 4)
    #   lt.to_s #=> 02:03:04
    def to_s
      s = "%02d:%02d:%02d" % [@hour, @min, @sec]
      s << ("%11.9f" % (@sec - @sec.floor))[1..] unless Integer === @sec
      s
    end
  end

  # call-seq:
  #
  #   parse(toml_src, symbolize_names: boolean) -> Object
  #
  # Decodes a TOML string.
  #
  #   PerfectTOML.parse("key = 42")  #=> { "key" => 42 }
  #
  #   src = <<~END
  #     [foo]
  #     bar = "baz"
  #   END
  #   PerfectTOML.parse(src)  #=> { "foo" => { "bar" => "baz" } }
  #
  # All keys in the Hash are String by default.
  # If a keyword `symbolize_names` is specficied as truthy,
  # all keys in the Hash will be Symbols.
  #
  #   PerfectTOML.parse("key = 42", symbolize_names: true)  #=> { :key => 42 }
  #
  #   src = <<~END
  #     [foo]
  #     bar = "baz"
  #   END
  #   PerfectTOML.parse(src, symbolize_names: true)  #=> { :key => { :bar => "baz" } }
  def self.parse(toml_src, **opts)
    Parser.new(toml_src, **opts).parse
  end

  # call-seq:
  #
  #   load_file(filename, symbolize_names: boolean) -> Object
  #
  # Loads a TOML file.
  #
  #   # test.toml
  #   #   key = 42
  #   PerfectTOML.load_file("test.toml") #=> { "key" => 42 }
  #
  # See PerfectTOML.parse for options.
  def self.load_file(io, **opts)
    io = File.open(io, encoding: "UTF-8") unless IO === io

    parse(io.read, **opts)
  end

  # call-seq:
  #
  #   generate(hash, sort_keys: false, use_literal_string: false, use_multiline_string: false, use_dot: false) -> String
  #
  # Encode a Hash in TOML format.
  #
  #   PerfectTOML.generate({ key: 42 })
  #   # output:
  #   #   key = 42
  #
  # The order of hashes are respected by default.
  # If you want to sort them, you can use +sort_keys+ keyword:
  #
  #   PerfectTOML.generate({ z: 1, a: 2 })
  #   # output:
  #   #   z = 1
  #   #   a = 2
  #
  #   PerfectTOML.generate({ z: 1, a: 2 }, sort_keys: true)
  #   # output:
  #   #   a = 2
  #   #   z = 1
  #
  # By default, all strings are quoted by quotation marks.
  # If +use_literal_string+ keyword is specified as truthy,
  # it prefers a literal string quoted by single quotes:
  #
  #   PerfectTOML.generate({ a: "foo" })
  #   # output:
  #   #   a = "foo"
  #
  #   PerfectTOML.generate({ a: "foo" }, use_literal_string: true)
  #   # output:
  #   #   a = 'foo'
  #
  # Multiline strings are not used by default.
  # If +use_multiline_string+ keyword is specified as truthy,
  # it uses a multiline string if the string contains a newline.
  #
  #   PerfectTOML.generate({ a: "foo\nbar" })
  #   # output:
  #   #   a = "foo\nbar"
  #
  #   PerfectTOML.generate({ a: "foo\nbar" }, use_multiline_string: true)
  #   # output:
  #   #   a = """
  #   #   foo
  #   #   bar"
  #
  # By default, dotted keys are used only in a header.
  # If +use_dot+ keyword is specified as truthy,
  # it uses a dotted key only when a subtree does not branch.
  #
  #   PerfectTOML.generate({ a: { b: { c: { d: 42 } } } })
  #   # output:
  #   #   [a.b.c]
  #   #   d = 42
  #
  #   PerfectTOML.generate({ a: { b: { c: { d: 42 } } } }, use_dot: true)
  #   # output:
  #   #   a.b.c.d = 42
  def self.generate(hash, **opts)
    out = +""
    Generator.new(hash, out, **opts).generate
    out
  end

  # call-seq:
  #
  #   save_file(filename, hash, symbolize_names: boolean) -> Object
  #
  # Saves a Hash into a file in TOML format.
  #
  #   PerfectTOML.save_file("out.toml", { key: 42 })
  #   # out.toml
  #   #   key = 42
  #
  # See PerfectTOML.generate for options.
  def self.save_file(io, hash, **opts)
    io = File.open(io, mode: "w", encoding: "UTF-8") unless IO === io
    Generator.new(hash, io, **opts).generate
  ensure
    io.close
  end

  class ParseError < StandardError; end

  class Parser # :nodoc:
    def initialize(src, symbolize_names: false)
      @s = StringScanner.new(src)
      @symbolize_names = symbolize_names
      @root_node = @topic_node = Node.new(1, nil)
    end

    def parse
      parse_toml
    end

    private

    # error handling

    def error(msg)
      prev = @s.string.byteslice(0, @s.pos)
      last_newline = prev.rindex("\n")
      bol = last_newline ? prev[0, last_newline + 1].bytesize : 0
      lineno = prev.count("\n") + 1
      column = @s.pos - bol + 1
      raise ParseError, "#{ msg } at line %d column %d" % [lineno, column]
    end

    def unterminated_string_error
      error "unterminated string"
    end

    def unexpected_error
      if @s.eos?
        error "unexpected end"
      elsif @s.scan(/[A-Za-z0-9_\-]+/)
        str = @s[0]
        @s.unscan
        error "unexpected identifier found: #{ str.dump }"
      else
        error "unexpected character found: #{ @s.peek(1).dump }"
      end
    end

    def redefine_key_error(keys, dup_key)
      @s.pos = @keys_start_pos
      keys = (keys + [dup_key]).map {|key| Generator.escape_key(key) }.join(".")
      error "cannot redefine `#{ keys }`"
    end

    # helpers for parsing

    def skip_spaces
      @s.skip(/(?:[\t\n ]|\r\n|#[^\x00-\x08\x0a-\x1f\x7f]*(?:\n|\r\n))+/)

      skip_comment if @s.check(/#/)
    end

    def skip_comment
      return if @s.skip(/#[^\x00-\x08\x0a-\x1f\x7f]*(?:\n|\r\n|\z)/)

      @s.skip(/[^\x00-\x08\x0a-\x1f\x7f]*/)
      unexpected_error
    end

    def skip_rest_of_line
      @s.skip(/[\t ]+/)
      case
      when @s.check(/#/) then skip_comment
      when @s.skip(/\n|\r\n/) || @s.eos?
      else
        unexpected_error
      end
    end

    # parsing for strings

    ESCAPE_CHARS = {
      ?b => ?\b, ?t => ?\t, ?n => ?\n, ?f => ?\f, ?r => ?\r, ?" => ?", ?\\ => ?\\
    }

    def parse_escape_char
      if @s.skip(/\\/)
        if @s.skip(/([btnmfr"\\])|u([0-9A-Fa-f]{4})|U([0-9A-Fa-f]{8})/)
          @s[1] ? ESCAPE_CHARS[@s[1]] : (@s[2] || @s[3]).hex.chr("UTF-8")
        else
          unterminated_string_error if @s.eos?
          error "invalid escape character in string: #{ @s.peek(1).dump }"
        end
      else
        unterminated_string_error if @s.eos?
        error "invalid character in string: #{ @s.peek(1).dump }"
      end
    end

    def parse_basic_string
      str = +""
      while true
        str << @s.scan(/[^\x00-\x08\x0a-\x1f\x7f"\\]*/)
        return str if @s.skip(/"/)
        str << parse_escape_char
      end
    end

    def parse_multiline_basic_string
      # skip a newline
      @s.skip(/\n|\r\n/)

      str = +""
      while true
        str << @s.scan(/[^\x00-\x08\x0b\x0c\x0e-\x1f\x7f"\\]*/)
        delimiter = @s.skip(/"{1,5}/)
        if delimiter
          str << "\"" * (delimiter % 3)
          return str if delimiter >= 3
          next
        end
        next if @s.skip(/\\[\t ]*(?:\n|\r\n)(?:[\t\n ]|\r\n)*/)
        str << parse_escape_char
      end
    end

    def parse_literal_string
      str = @s.scan(/[^\x00-\x08\x0a-\x1f\x7f']*/)
      return str if @s.skip(/'/)
      unterminated_string_error if @s.eos?
      error "invalid character in string: #{ @s.peek(1).dump }"
    end

    def parse_multiline_literal_string
      # skip a newline
      @s.skip(/\n|\r\n/)

      str = +""
      while true
        str << @s.scan(/[^\x00-\x08\x0b\x0c\x0e-\x1f\x7f']*/)
        if delimiter = @s.skip(/'{1,5}/)
          str << "'" * (delimiter % 3)
          return str if delimiter >= 3
          next
        end
        unterminated_string_error if @s.eos?
        error "invalid character in string: #{ @s.peek(1).dump }"
      end
    end

    # parsing for date/time

    def parse_datetime(preread_len)
      str = @s[0]
      pos = @s.pos - preread_len
      year, month, day = @s[1], @s[2], @s[3]
      if @s.skip(/[T ](\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/i)
        str << @s[0]
        hour, min, sec = @s[1], @s[2], @s[3]
        raise ArgumentError unless (0..23).cover?(hour.to_i)
        zone = @s.scan(/(Z)|[-+]\d{2}:\d{2}/i)
        time = Time.new(year, month, day, hour, min, sec.to_r, @s[1] ? "UTC" : zone)
        if zone
          time
        else
          LocalDateTime.new(year, month, day, hour, min, sec)
        end
      else
        Time.new(year, month, day, 0, 0, 0, "Z") # parse check
        LocalDate.new(year, month, day)
      end
    rescue ArgumentError
      @s.pos = pos
      error "failed to parse date or datetime \"#{ str }\""
    end

    def parse_time(preread_len)
      hour, min, sec = @s[1], @s[2], @s[3]
      Time.new(1970, 1, 1, hour, min, sec.to_r, "Z") # parse check
      LocalTime.new(hour, min, sec)
    rescue ArgumentError
      @s.pos -= preread_len
      error "failed to parse time \"#{ @s[0] }\""
    end

    # parsing for inline array/table

    def parse_array
      ary = []
      while true
        skip_spaces
        break if @s.skip(/\]/)
        ary << parse_value
        skip_spaces
        next if @s.skip(/,/)
        break if @s.skip(/\]/)
        unexpected_error
      end
      ary
    end

    def parse_inline_table
      @s.skip(/[\t ]*/)
      if @s.skip(/\}/)
        {}
      else
        tmp_node = Node.new(1, nil)
        while true
          @keys_start_pos = @s.pos
          keys = parse_keys
          @s.skip(/[\t ]*/)
          unexpected_error unless @s.skip(/=[\t ]*/)
          define_value(tmp_node, keys)
          @s.skip(/[\t ]*/)
          next if @s.skip(/,[\t ]*/)
          break if @s.skip(/\}/)
          unexpected_error
        end
        tmp_node.table
      end
    end

    # parsing key and value

    def parse_keys
      keys = []
      while true
        case
        when key = @s.scan(/[A-Za-z0-9_\-]+/)
        when @s.skip(/"/) then key = parse_basic_string
        when @s.skip(/'/) then key = parse_literal_string
        else
          unexpected_error
        end

        key = key.to_sym if @symbolize_names

        keys << key

        @s.skip(/[\t ]*/)
        next if @s.skip(/\.[\t ]*/)

        return keys
      end
    end

    def parse_value
      case
      when @s.skip(/"/)
        @s.skip(/""/) ? parse_multiline_basic_string : parse_basic_string
      when @s.skip(/'/)
        @s.skip(/''/) ? parse_multiline_literal_string : parse_literal_string
      when len = @s.skip(/(-?\d{4})-(\d{2})-(\d{2})/)
        parse_datetime(len)
      when len = @s.skip(/(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/)
        parse_time(len)
      when val = @s.scan(/0x\h(?:_?\h)*|0o[0-7](?:_?[0-7])*|0b[01](?:_?[01])*/)
        Integer(val)
      when val1 = @s.scan(/[+\-]?(?:0|[1-9](?:_?[0-9])*)/)
        val2 = @s.scan(/\.[0-9](?:_?[0-9])*/)
        val3 = @s.scan(/[Ee][+\-]?[0-9](?:_?[0-9])*/)
        if val2 || val3
          Float(val1 + (val2 || "") + (val3 || ""))
        else
          Integer(val1)
        end
      when @s.skip(/true\b/)
        true
      when @s.skip(/false\b/)
        false
      when @s.skip(/\[/)
        parse_array
      when @s.skip(/\{/)
        parse_inline_table
      when val = @s.scan(/([+\-])?(?:(inf)|(nan))\b/)
        @s[2] ? @s[1] == "-" ? -Float::INFINITY : Float::INFINITY : Float::NAN
      else
        unexpected_error
      end
    end

    # object builder

    class Node # :nodoc:
      # This is an internal data structure to create a Ruby object from TOML.
      # A node corresponds to a table in TOML.
      #
      # There are five node types:
      #
      # 1. declared
      #
      #   Declared as a table by a dotted-key header, but not defined yet.
      #   This type may be changed to "1. defined_by_header".
      #
      #   Example 1: "a" and "a.b" of "[a.b.c]"
      #   Example 2: "a" and "a.b" of "[[a.b.c]]".
      #
      # 2. defined_by_header
      #
      #   Defined as a table by a header. This type is final.
      #
      #   Example: "a.b.c" of "[a.b.c]"
      #
      # 3. defined_by_dot
      #
      #   Defined as a table by a dotted-key value definition.
      #   This type is final.
      #
      #   Example: "a" and "a.b" of "a.b.c = val"
      #
      #   Note: we need to distinguish between defined_by_header and
      #   defined_by_dot because defined_by_dot can modify a table of
      #   defined_by_dot:
      #
      #       a.b.c=1  # define "a.b" as defined_by_dot
      #       a.b.d=2  # able to modify "a.b" (add "d" to "a.b")
      #
      #   but cannot modify a table of defined_by_header:
      #
      #       [a.b]    # define "a.b" as defined_by_header
      #       c=1
      #       [a]
      #       b.d=2    # unable to modify "a.b"
      #
      # 4. defined_as_array
      #
      #   Defined as an array of tables. This type is final, but this node
      #   may be replaced with a new element of the array. A node has a
      #   reference to the last table in the array.
      #
      #   Example: "a.b.c" of "[[a.b.c]]"
      #
      # 5. defined_as_value
      #
      #   Defined as a value. This type is final.
      #
      #   Example: "a.b.c" of "a.b.c = val"
      def initialize(type, parent)
        @type = type
        @children = {}
        @table = {}
        @parent = parent
      end

      attr_accessor :type
      attr_reader :children, :table

      Terminal = Node.new(:defined_as_value, nil)

      def path
        return [] unless @parent
        key, = @parent.children.find {|key, child| child == self }
        @parent.path + [key]
      end
    end

    def extend_node(node, key, type)
       new_node = Node.new(type, node)
       node.table[key] = new_node.table
       node.children[key] = new_node
    end

    # handle "a.b" part of "[a.b.c]" or "[[a.b.c]]"
    def declare_tables(keys)
      node = @root_node
      keys.each_with_index do |key, i|
        child_node = node.children[key]
        if child_node
          node = child_node
          redefine_key_error(keys[0, i], key) if node.type == :defined_as_value
        else
          node = extend_node(node, key, :declared)
        end
      end
      node
    end

    # handle "a.b.c" part of "[a.b.c]"
    def define_table(node, key)
      child_node = node.children[key]
      if child_node
        redefine_key_error(node.path, key) if child_node.type != :declared
        child_node.type = :defined_by_header
        child_node
      else
        extend_node(node, key, :defined_by_header)
      end
    end

    # handle "a.b.c" part of "[[a.b.c]]"
    def define_array(node, key)
      new_node = Node.new(:defined_as_array, node)
      child_node = node.children[key]
      if child_node
        redefine_key_error(node.path, key) if child_node.type != :defined_as_array
        node.table[key] << new_node.table
      else
        node.table[key] = [new_node.table]
      end
      node.children[key] = new_node
    end

    # handle "a.b.c = val"
    def define_value(node, keys)
      if keys.size >= 2
        *keys, last_key = keys
        keys.each_with_index do |key, i|
          child_node = node.children[key]
          if child_node
            redefine_key_error(node.path, key) if child_node.type != :defined_by_dot
            node = child_node
          else
            node = extend_node(node, key, :defined_by_dot)
          end
        end
      else
        last_key = keys.first
      end
      redefine_key_error(node.path, last_key) if node.children[last_key]
      node.table[last_key] = parse_value
      node.children[last_key] = Node::Terminal
    end

    def parse_toml
      while true
        skip_spaces

        break if @s.eos?

        case @s.skip(/\[\[?/)
        when 1
          @keys_start_pos = @s.pos - 1
          @s.skip(/[\t ]*/)
          *keys, last_key = parse_keys
          unexpected_error unless @s.skip(/\]/)
          skip_rest_of_line
          @topic_node = define_table(declare_tables(keys), last_key)

        when 2
          @keys_start_pos = @s.pos - 2
          @s.skip(/[\t ]*/)
          *keys, last_key = parse_keys
          unexpected_error unless @s.skip(/\]\]/)
          skip_rest_of_line
          @topic_node = define_array(declare_tables(keys), last_key)

        else
          @keys_start_pos = @s.pos
          keys = parse_keys
          unexpected_error unless @s.skip(/=[\t ]*/)
          define_value(@topic_node, keys)
          skip_rest_of_line
        end
      end

      @root_node.table
    end
  end

  class Generator # :nodoc:
    def initialize(obj, out, sort_keys: false, use_literal_string: false, use_multiline_string: false, use_dot: false)
      @obj = obj.to_hash
      @out = out
      @first_output = true

      @sort_keys = sort_keys
      @use_literal_string = use_literal_string
      @use_multiline_string = use_multiline_string
      @use_dot = use_dot
    end

    def generate
      generate_hash(@obj, "", false)
      @out
    end

    def self.escape_key(key)
      new({}, "").send(:escape_key, key)
    end

    def self.escape_basic_string(str)
      str = str.gsub(/["\\\x00-\x08\x0a-\x1f\x7f]/) do
        c = ESCAPE_CHARS[$&]
        c ? "\\" + c : "\\u%04x" % $&.ord
      end
      "\"#{ str }\""
    end

    private

    def escape_key(key)
      key = key.to_s
      if key =~ /\A[A-Za-z0-9_\-]+\z/
        key
      else
        escape_string(key)
      end
    end

    ESCAPE_CHARS = {
      ?\b => ?b, ?\t => ?t, ?\n => ?n, ?\f => ?f, ?\r => ?r, ?" => ?", ?\\ => ?\\
    }

    def escape_multiline_string(str)
      if @use_literal_string && str =~ /\A'{0,2}(?:[^\x00-\x08\x0b\x0c\x0e-\x1f\x7f']+(?:''?|\z))*\z/
        "'''\n#{ str }'''"
      else
        str = str.gsub(/(""")|([\\\x00-\x08\x0b\x0c\x0e-\x1f\x7f])/) do
          $1 ? '\\"""' : "\\u%04x" % $2.ord
        end
        "\"\"\"\n#{ str }\"\"\""
      end
    end

    def escape_string(str)
      if @use_literal_string && str =~ /\A[^\x00-\x08\x0a-\x1f\x7f']*\z/
        "'#{ str }'"
      else
        Generator.escape_basic_string(str)
      end
    end

    def generate_hash(hash, path, array_type)
      values = []
      children = []
      dup_check = {}

      hash.each do |key, val|
        k = key.to_s
        if dup_check[k]
          raise ArgumentError, "duplicated key: %p and %p" % [dup_check[k], key]
        end
        dup_check[k] = key

        k = escape_key(k)

        tbl = Hash.try_convert(val)
        if tbl
          k2, val = dot_usable(tbl) if @use_dot
          if k2
            values << [k + "." + k2, val]
          else
            children << [:table, k, tbl]
          end
        else
          ary = Array.try_convert(val)
          ary = ary&.map do |v|
            v = Hash.try_convert(v)
            break unless v
            v
          end
          if ary && !ary.empty?
            children << [:array, k, ary]
          else
            values << [k, val]
          end
        end
      end

      if !path.empty? && (!values.empty? || hash.empty?) || array_type
        @out << "\n" unless @first_output
        if array_type
          @out << "[[" << path << "]]\n"
        else
          @out << "[" << path << "]\n"
        end
        @first_output = false
      end

      unless values.empty?
        values = values.sort if @sort_keys
        values.each do |key, val|
          @out << key << " = "
          generate_value(val)
          @out << "\n"
        end
        @first_output = false
      end

      unless children.empty?
        children = children.sort if @sort_keys
        children.each do |type, key, val|
          path2 = path.empty? ? key : path + "." + key
          if type == :table
            generate_hash(val, path2, false)
          else
            val.each do |hash|
              generate_hash(hash, path2, true)
            end
          end
        end
      end
    end

    def dot_usable(tbl)
      return nil if tbl.size != 1
      key, val = tbl.first
      case val
      when Integer, true, false, Float, Time, String
        [escape_key(key), val]
      when Hash
        path, val = dot_usable(val)
        if path
          [escape_key(key) + "." + path, val]
        else
          nil
        end
      else
        nil
      end
    end

    def generate_value(val)
      case val
      when Integer, true, false
        @out << val.to_s
      when Float
        case
        when val.infinite?
          @out << (val > 0 ? "inf" : "-inf")
        when val.nan?
          @out << "nan"
        else
          @out << val.to_s
        end
      when Time
        @out << val.strftime("%Y-%m-%dT%H:%M:%S")
        @out << val.strftime(".%N") if val != val.floor
        @out << (val.utc? ? "Z" : val.strftime("%:z"))
      when String
        if @use_multiline_string && val.include?("\n")
          @out << escape_multiline_string(val)
        else
          @out << escape_string(val)
        end
      when Array
        @out << "["
        first = true
        val.each do |v|
          @out << ", " unless first
          generate_value(v)
          first = false
        end
        @out << "]"
      when Hash
        if val.empty?
          @out << "{}"
        else
          @out << "{ "
          first = true
          val.each do |k, v|
            @out << ", " unless first
            @out << escape_key(k) << " = "
            generate_value(v)
            first = false
          end
          @out << " }"
        end
      else
        @out << val.to_inline_toml
      end
    end
  end
end
