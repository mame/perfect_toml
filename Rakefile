require "bundler/gem_tasks"
require "rake/testtask"
require "rdoc/task"

Rake::TestTask.new(:core_test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

TOML_TEST = "./toml-test-v1.6.0-linux-amd64"

file TOML_TEST do
  require "open-uri"
  require "zlib"
  URI.open("https://github.com/toml-lang/toml-test/releases/download/v1.6.0/toml-test-v1.6.0-linux-amd64.gz", "rb") do |f|
    File.binwrite(TOML_TEST, Zlib::GzipReader.new(f).read)
    File.chmod(0o755, TOML_TEST)
  end
end

task :toml_decoder_test => TOML_TEST do
  sh TOML_TEST, "--toml", "1.0.0",
    # https://github.com/toml-lang/toml-test/pull/174
    "--skip", "invalid/control/multi-cr",
    "--skip", "invalid/control/rawmulti-cr",
    "./tool/decoder.rb"
end

task :toml_encoder_test => TOML_TEST do
  ["0000", "1000", "0010", "0001", "0011"].each do |mode|
    ENV["TOML_ENCODER_USE_DOT"] = mode[0]
    ENV["TOML_ENCODER_SORT_KEYS"] = mode[1]
    ENV["TOML_ENCODER_USE_LITERAL_STRING"] = mode[2]
    ENV["TOML_ENCODER_USE_MULTILINE_STRING"] = mode[3]
    sh TOML_TEST, "--encoder", "./tool/encoder.rb"
  end
end

task :test => [:core_test, :toml_decoder_test, :toml_encoder_test]

task default: :test

Rake::RDocTask.new do |rdoc|
  files =["README.md", "LICENSE", "lib/perfect_toml.rb"]
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.md"
  rdoc.title = "PerfectTOML Docs"
  rdoc.rdoc_dir = "doc/rdoc"
end
