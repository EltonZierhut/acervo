require "test_helper"

# Fallback da interface (SPA): o Rails entrega o index.html do React nas rotas de navegação.
class SpaControllerTest < ActionDispatch::IntegrationTest
  INDEX = SpaController::INDEX_PATH
  HTML = "<!doctype html><html><body><div id=\"root\"></div></body></html>".freeze

  setup do
    @original = INDEX.exist? ? INDEX.read : nil
    INDEX.dirname.mkpath
    INDEX.write(HTML)
  end

  teardown do
    if @original
      INDEX.write(@original)
    else
      INDEX.delete if INDEX.exist?
    end
  end

  def get_html(path)
    get path, headers: { "Accept" => "text/html" }
  end

  test "entrega a interface na raiz, sem login e sem cache" do
    get_html "/"
    assert_response :ok
    assert_equal HTML, response.body
    assert_equal "text/html", response.media_type
    assert_includes response.headers["Cache-Control"], "no-cache"
  end

  test "entrega a interface em rotas de navegação abertas diretamente" do
    get_html "/codigos/projetos"
    assert_response :ok
    assert_equal HTML, response.body
  end

  test "rotas de API inexistentes não caem na interface" do
    get_html "/api/v1/naoexiste"
    assert_response :not_found
    assert_not_equal HTML, response.body
  end

  test "assets inexistentes não caem na interface" do
    get_html "/assets/naoexiste.js"
    assert_response :not_found
  end

  test "requisições que não aceitam HTML não recebem a interface" do
    get "/codigos", headers: { "Accept" => "application/json" }
    assert_response :not_found
  end

  test "sem o build da interface, avisa que ela roda pelo Vite" do
    INDEX.delete
    get_html "/"
    assert_response :not_found
    assert_match "Interface não compilada", response.body
  end
end
