require "test_helper"

# SC-007: os fluxos do módulo Códigos continuam funcionando com login.
class CodesApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  test "módulos habilitados" do
    get api_v1_modules_path
    assert_response :ok
    assert_includes json.map { |m| m["key"] }, "codes"
  end

  test "CRUD e busca de códigos" do
    post api_v1_codes_snippets_path, as: :json, params: {
      snippet: { title: "Hook de debounce", language: "TypeScript", tags: "React, hooks",
                 content: "export function useDebounce(value) {}" }
    }
    assert_response :created
    id = json["id"]
    assert_equal "typescript", json["language"]
    assert_equal %w[react hooks], json["tags"]

    get api_v1_codes_snippets_path, params: { q: "useDeb" }
    assert_response :ok
    assert_equal [ id ], json["data"].map { |s| s["id"] }
    assert_equal 1, json.dig("meta", "total")

    get api_v1_codes_snippet_path(id)
    assert_response :ok

    patch api_v1_codes_snippet_path(id), as: :json, params: { snippet: { title: "Debounce" } }
    assert_response :ok
    assert_equal "Debounce", json["title"]

    delete api_v1_codes_snippet_path(id), as: :json
    assert_response :no_content
  end

  test "validação retorna 422 com mensagens" do
    post api_v1_codes_snippets_path, as: :json, params: { snippet: { title: "" } }
    assert_response :unprocessable_entity
    assert json["errors"].any?
  end

  test "projetos com contagem de códigos e busca geral" do
    post api_v1_codes_projects_path, as: :json, params: { project: { name: "Acervo", tags: [ "rails" ] } }
    assert_response :created
    project_id = json["id"]

    post api_v1_codes_snippets_path, as: :json, params: {
      snippet: { title: "Backup", content: "pg_dump acervo", project_id: }
    }
    assert_response :created

    get api_v1_codes_projects_path
    assert_response :ok
    assert_equal 1, json.find { |p| p["id"] == project_id }["snippets_count"]

    get api_v1_codes_project_path(project_id)
    assert_equal 1, json["snippets"].size

    get api_v1_codes_search_path, params: { q: "acervo" }
    assert_response :ok
    assert_equal 1, json["projects"].size
    assert_equal 1, json["snippets"].size
  end
end
