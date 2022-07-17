require "test_helper"
require "tempfile"

class LoadSaveFileTest < Test::Unit::TestCase
  def test_load_file
    Tempfile.create(["toml-test", ".toml"]) do |t|
      t << "load = 42\n"
      t.close
      assert_equal({ "load" => 42 }, PerfectTOML.load_file(t.path))
    end
  end

  def test_save_file
    Tempfile.create(["toml-test", ".toml"]) do |t|
      t.close
      PerfectTOML.save_file(t.path, { "save" => 42 })
      assert_equal("save = 42\n", File.read(t.path))
    end
  end
end
