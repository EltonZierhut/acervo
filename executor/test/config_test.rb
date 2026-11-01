require_relative "test_helper"

class ConfigTest < Minitest::Test
  include TestSupport

  def write(content, mode)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, content)
      File.chmod(mode, path)
      yield path
    end
  end

  VALID = "api_url: https://a.test\nexecutor_token: x\nclaude_oauth_token: y\n".freeze

  def test_recusa_arquivo_aberto_a_outros_usuarios
    write(VALID, 0o644) do |path|
      error = assert_raises(AcervoExecutor::Error) { AcervoExecutor::Config.load(path) }
      assert_includes error.message, "chmod 600"
    end
  end

  def test_carrega_com_permissao_600
    write(VALID, 0o600) { |path| assert_equal "x", AcervoExecutor::Config.load(path).executor_token }
  end

  def test_informa_o_que_falta
    error = assert_raises(AcervoExecutor::Error) { AcervoExecutor::Config.new("api_url" => "https://a.test") }
    assert_includes error.message, "executor_token"
  end

  def test_exige_https_fora_do_localhost
    assert_raises(AcervoExecutor::Error) { config("api_url" => "http://acervo.test") }
    assert_raises(AcervoExecutor::Error) { config("api_url" => "http://localhost.evil.test") }
    assert_equal "http://localhost:3000", config("api_url" => "http://localhost:3000/").api_url
  end

  def test_imagem_por_repositorio
    cfg = config("image" => "padrao:1", "images" => { "a/b" => "especial:1" })
    assert_equal "especial:1", cfg.image_for("a/b")
    assert_equal "padrao:1", cfg.image_for("c/d")
    assert_equal "acervo-agent:latest", config.image_for("a/b")
  end
end
