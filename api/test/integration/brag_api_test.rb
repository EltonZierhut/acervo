require "test_helper"

class BragApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  def create_entry(**attrs)
    post api_v1_brag_entries_path, as: :json, params: { entry: { title: "Entreguei X", **attrs } }
    assert_response :created
    json
  end

  test "registro rápido só com o título usa a data de hoje" do
    entry = create_entry
    assert_equal Date.current.to_s, entry["achieved_on"]
    assert_equal [], entry["tags"]
    assert_equal [], entry["evidence_links"]
  end

  test "título é obrigatório" do
    post api_v1_brag_entries_path, as: :json, params: { entry: { title: "  " } }
    assert_response :unprocessable_entity
    assert json["fields"].key?("title")
  end

  test "guarda todos os campos, com Markdown preservado" do
    entry = create_entry(achieved_on: "2026-03-10", description: "# Feito\n- item", category: "Entrega",
                         tags: "Rails, api", impact: "Menos erros", metrics: "-30% de falhas",
                         evidence_links: "https://exemplo.com/a\nhttps://exemplo.com/b", project: "Acervo")
    assert_equal "# Feito\n- item", entry["description"]
    assert_equal %w[rails api], entry["tags"]
    assert_equal %w[https://exemplo.com/a https://exemplo.com/b], entry["evidence_links"]
    assert_equal "Acervo", entry["project"]
  end

  test "links de evidência precisam ser http(s)" do
    post api_v1_brag_entries_path, as: :json, params: { entry: { title: "x", evidence_links: [ "javascript:alert(1)" ] } }
    assert_response :unprocessable_entity
  end

  test "lista por data, filtra e busca" do
    old = create_entry(achieved_on: "2025-01-01", category: "Mentoria", tags: "time")
    recent = create_entry(achieved_on: "2026-05-01", title: "Migração de banco", impact: "ganho de performance")

    get api_v1_brag_entries_path
    assert_equal [ recent["id"], old["id"] ], json["data"].map { |e| e["id"] }

    get api_v1_brag_entries_path, params: { year: 2025 }
    assert_equal [ old["id"] ], json["data"].map { |e| e["id"] }
    get api_v1_brag_entries_path, params: { category: "Mentoria" }
    assert_equal [ old["id"] ], json["data"].map { |e| e["id"] }
    get api_v1_brag_entries_path, params: { tag: "time" }
    assert_equal [ old["id"] ], json["data"].map { |e| e["id"] }
    get api_v1_brag_entries_path, params: { q: "perform" }
    assert_equal [ recent["id"] ], json["data"].map { |e| e["id"] }
  end

  test "atualiza e apaga" do
    id = create_entry["id"]
    patch api_v1_brag_entry_path(id), as: :json, params: { entry: { title: "Novo" } }
    assert_response :ok
    assert_equal "Novo", json["title"]
    delete api_v1_brag_entry_path(id), as: :json
    assert_response :no_content
  end
end
