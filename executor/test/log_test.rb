require_relative "test_helper"

class LogTest < Minitest::Test
  include TestSupport

  def test_oculta_credenciais_no_terminal_e_no_arquivo
    io = StringIO.new
    log = AcervoExecutor::Log.new(secrets: %w[segredo], io:)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "x/run.log")
      log.to_file(path) { log.info("a segredo ghp_#{'a' * 30} sk-ant-#{'b' * 30}") }
      [ io.string, File.read(path) ].each do |text|
        refute_includes text, "segredo"
        refute_includes text, "ghp_"
        refute_includes text, "sk-ant-"
      end
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
  end
end
