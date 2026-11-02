require "test_helper"

# Arquivos do app instalável: na raiz, sem login e com o cache certo.
class PwaControllerTest < ActionDispatch::IntegrationTest
  DIR = PwaController::DIR

  setup do
    @created = []
    write("sw.js", "// sw")
    write("manifest.webmanifest", "{}")
    write("icons/icon-192.png", "png")
  end

  teardown { @created.each { |p| p.delete if p.exist? } }

  def write(name, content)
    path = DIR.join(name)
    path.dirname.mkpath
    return if path.exist?

    path.write(content)
    @created << path
  end

  test "sw.js é entregue na raiz, sem login e sem cache" do
    get "/sw.js"
    assert_response :ok
    assert_equal "text/javascript", response.media_type
    assert_includes response.headers["Cache-Control"], "no-cache"
  end

  test "manifesto é entregue sem cache" do
    get "/manifest.webmanifest"
    assert_response :ok
    assert_equal "application/manifest+json", response.media_type
    assert_includes response.headers["Cache-Control"], "no-cache"
  end

  test "ícones são entregues com cache curto" do
    get "/icons/icon-192.png"
    assert_response :ok
    assert_equal "image/png", response.media_type
    assert_includes response.headers["Cache-Control"], "max-age=86400"
  end

  test "ícone inexistente ou com caminho fora da pasta dá 404" do
    get "/icons/naoexiste.png"
    assert_response :not_found
    get "/icons/..%2Fsw.png"
    assert_response :not_found
  end

  test "sem o build, sw.js dá 404 em vez de cair na interface" do
    DIR.join("sw.js").delete
    get "/sw.js", headers: { "Accept" => "text/html" }
    assert_response :not_found
  end
end
