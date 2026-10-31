require "test_helper"

# SC-007: os fluxos do módulo Códigos continuam funcionando com login.
class CodesApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  def create_note(**attrs)
    post api_v1_codes_snippets_path, as: :json, params: { snippet: { content: "ls", **attrs } }
    assert_response :created
    json
  end

  def search(term)
    get api_v1_codes_snippets_path, params: { q: term }
    assert_response :ok
    json["data"].map { |s| s["id"] }
  end

  test "módulos habilitados" do
    get api_v1_modules_path
    assert_response :ok
    assert_includes json.map { |m| m["key"] }, "codes"
  end

  test "cria nota só com o conteúdo, preservando o texto" do
    content = "\n  rails runner 'puts 1'\n\n\techo $HOME\n"
    note = create_note(content:)

    assert_nil note["title"]
    assert_equal "rails runner 'puts 1'", note["display_title"]
    assert_equal content, note["content"]

    get api_v1_codes_snippet_path(note["id"])
    assert_response :ok
    assert_equal content, json["content"]
  end

  test "tags enviadas como texto são separadas" do
    assert_equal %w[react hooks], create_note(tags: "React, hooks")["tags"]
  end

  test "listagem traz notas recentes primeiro e sem conteúdo" do
    old = create_note(content: "antiga")
    recent = create_note(content: "nova")
    ::Codes::Snippet.find(old["id"]).update_column(:updated_at, 1.day.ago)

    get api_v1_codes_snippets_path
    assert_response :ok
    assert_equal [ recent["id"], old["id"] ], json["data"].map { |s| s["id"] }
    assert_equal "nova", json["data"].first["display_title"]
    assert_not_includes json["data"].first.keys, "content"
    assert_not_includes json["data"].first.keys, "project_id"
    assert_equal 2, json.dig("meta", "total")
  end

  test "busca por palavra, pedaços de conteúdo e de tag" do
    id = create_note(title: "Hook", content: "function useDebounce(value) {}", tags: "postgres")["id"]
    create_note(content: "outra coisa")

    assert_equal [ id ], search("Hook")
    assert_equal [ id ], search("useDeb")
    assert_equal [ id ], search("stgre")
  end

  test "busca aceita caracteres comuns em scripts" do
    id = create_note(content: "pg_dump > backup_$(date +%F).dump -- 'a' * b")["id"]

    assert_equal [ id ], search("$(date")
    assert_equal [ id ], search("'a'")
    [ "*", "--", "%", "\\" ].each { |term| search(term) }
  end

  test "conteúdo inválido retorna 422 e nada é salvo" do
    [ "", "  \n", "a" * (1.megabyte + 1), "a\u0000b" ].each do |content|
      assert_no_difference -> { ::Codes::Snippet.count } do
        post api_v1_codes_snippets_path, as: :json, params: { snippet: { content: } }
      end
      assert_response :unprocessable_entity
      assert json["errors"].any?
      assert json.dig("fields", "content").any?
    end
  end

  test "texto além do limite do índice de busca retorna 422" do
    content = (1..31_000).map { |i| Digest::MD5.hexdigest(i.to_s) }.join(" ")

    assert_no_difference -> { ::Codes::Snippet.count } do
      post api_v1_codes_snippets_path, as: :json, params: { snippet: { content: } }
    end
    assert_response :unprocessable_entity
    assert json.dig("fields", "content").any?
  end

  test "editar com conteúdo vazio mantém a versão anterior" do
    id = create_note(content: "original")["id"]

    patch api_v1_codes_snippet_path(id), as: :json, params: { snippet: { content: " " } }
    assert_response :unprocessable_entity
    assert_equal "original", ::Codes::Snippet.find(id).content
  end

  test "editar atualiza a nota e updated_at só muda com alteração real" do
    note = create_note(content: "a", tags: "x, y")
    snippet = ::Codes::Snippet.find(note["id"])
    snippet.update_column(:updated_at, 1.day.ago)
    before = snippet.reload.updated_at

    patch api_v1_codes_snippet_path(note["id"]), as: :json, params: { snippet: { content: "a", tags: "x, y" } }
    assert_response :ok
    assert_equal before, snippet.reload.updated_at

    patch api_v1_codes_snippet_path(note["id"]), as: :json, params: { snippet: { title: "Novo" } }
    assert_response :ok
    assert_equal "Novo", json["display_title"]
    assert_operator snippet.reload.updated_at, :>, before
  end

  test "apaga nota, que some da busca" do
    id = create_note(content: "apagarei")["id"]

    delete api_v1_codes_snippet_path(id), as: :json
    assert_response :no_content
    assert_empty search("apagarei")

    get api_v1_codes_snippet_path(id)
    assert_response :not_found
  end

  test "project_id não é aceito e as rotas de projetos saíram" do
    assert_not_includes create_note(project_id: 1).keys, "project_id"

    assert_empty Rails.application.routes.routes.map { |r| r.path.spec.to_s }
      .grep(%r{/api/v1/codes/(projects|search)})
  end

  test "conteúdo das notas não aparece nos logs" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    assert_equal "[FILTERED]", filter.filter(content: "segredo")[:content]
  end
end
