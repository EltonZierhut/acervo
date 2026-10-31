require "test_helper"

# Request tests do módulo Iniciativas (contracts/initiatives-api.md da feature 005).
class InitiativesApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  def create_initiative(**attrs)
    post api_v1_initiatives_initiatives_path, as: :json, params: { initiative: { name: "Jogo", **attrs } }
    assert_response :created
    json
  end

  def create_task(initiative_id, **attrs)
    post api_v1_initiatives_initiative_tasks_path(initiative_id), as: :json, params: { task: { title: "Tarefa", **attrs } }
    assert_response :created
    json
  end

  def list_initiatives(**query)
    get api_v1_initiatives_initiatives_path, params: query
    assert_response :ok
    json["data"].map { |i| i["id"] }
  end

  test "módulo aparece na lista de módulos" do
    get api_v1_modules_path
    assert_includes json.map { |m| m["key"] }, "initiatives"
  end

  # Contextos

  test "cria, lista, renomeia e apaga contextos" do
    post api_v1_initiatives_contexts_path, as: :json, params: { context: { name: "Trabalho", color: "#2F6FED" } }
    assert_response :created
    context = json
    assert_equal({ "id" => context["id"], "name" => "Trabalho", "color" => "#2f6fed", "initiatives_count" => 0 }, context)

    create_initiative(context_id: context["id"])
    get api_v1_initiatives_contexts_path
    assert_equal 1, json.first["initiatives_count"]

    patch api_v1_initiatives_context_path(context["id"]), as: :json, params: { context: { name: "Emprego" } }
    assert_response :ok
    assert_equal "Emprego", json["name"]

    delete api_v1_initiatives_context_path(context["id"]), as: :json
    assert_response :no_content
    assert_nil ::Initiatives::Initiative.last.context_id
  end

  test "contexto repetido retorna 422" do
    ::Initiatives::Context.create!(name: "Casa")
    post api_v1_initiatives_contexts_path, as: :json, params: { context: { name: "CASA" } }
    assert_response :unprocessable_entity
    assert json.dig("fields", "name").any?
  end

  # Iniciativas

  test "cria iniciativa só com o nome" do
    initiative = create_initiative(name: "Jogo para a Steam", tags: "Godot, steam")

    assert_equal "planned", initiative["status"]
    assert_equal "medium", initiative["priority"]
    assert_equal %w[tasks milestones], initiative["sections"]
    assert_equal %w[godot steam], initiative["tags"]
    assert_nil initiative["context"]
    assert_nil initiative["description"]
    assert_equal({ "done" => 0, "total" => 0 }, initiative["progress"])
  end

  test "dados inválidos retornam 422 e nada é salvo" do
    invalid = [
      { name: " " },
      { name: "x", status: "bogus" },
      { name: "x", priority: "urgent" },
      { name: "x", sections: %w[decisions] },
      { name: "x", starts_on: "2026-11-10", due_on: "2026-11-01" },
      { name: "x", context_id: 0 },
      { name: "a\u0000b" }
    ]
    invalid.each do |attrs|
      assert_no_difference -> { ::Initiatives::Initiative.count } do
        post api_v1_initiatives_initiatives_path, as: :json, params: { initiative: attrs }
      end
      assert_response :unprocessable_entity, attrs.inspect
      assert json["errors"].any?
    end
  end

  test "detalhe traz contexto, descrição, seções e progresso" do
    context = ::Initiatives::Context.create!(name: "Jogo", color: "#7c3aed")
    id = create_initiative(context_id: context.id, description: "Plataforma 2D", sections: [ "tasks" ])["id"]
    create_task(id, status: "done")
    create_task(id)

    get api_v1_initiatives_initiative_path(id)
    assert_response :ok
    assert_equal({ "id" => context.id, "name" => "Jogo", "color" => "#7c3aed" }, json["context"])
    assert_equal "Plataforma 2D", json["description"]
    assert_equal [ "tasks" ], json["sections"]
    assert_equal({ "done" => 1, "total" => 2 }, json["progress"])
  end

  test "listagem esconde encerradas por padrão e filtra por status e contexto" do
    context = ::Initiatives::Context.create!(name: "Casa")
    active = create_initiative(status: "active")["id"]
    home = create_initiative(context_id: context.id)["id"]
    done = create_initiative(status: "done")["id"]

    assert_equal [ active, home ], list_initiatives
    assert_equal [ done ], list_initiatives(status: "done")
    assert_equal [ active, home, done ], list_initiatives(status: "all")
    assert_equal [ home ], list_initiatives(context_id: context.id)
    assert_equal [ active ], list_initiatives(context_id: "none")

    get api_v1_initiatives_initiatives_path
    assert_equal({ "done" => 0, "total" => 0 }, json["data"].first["progress"])
    assert_not_includes json["data"].first.keys, "description"
    assert_equal 2, json.dig("meta", "total")
  end

  test "busca por palavra, pedaço e caracteres especiais" do
    id = create_initiative(name: "Jogo para a Steam", description: "plataforma 2D", tags: "godot")["id"]
    create_initiative(name: "Reforma")

    assert_equal [ id ], list_initiatives(q: "Steam")
    assert_equal [ id ], list_initiatives(q: "atafor")
    assert_equal [ id ], list_initiatives(q: "odo")
    [ "$(", "*", "'", "%", "\\" ].each { |term| list_initiatives(q: term) }
  end

  test "paginação" do
    3.times { |i| create_initiative(name: "I#{i}") }
    get api_v1_initiatives_initiatives_path, params: { per_page: 2, page: 2 }
    assert_equal 1, json["data"].size
    assert_equal({ "page" => 2, "per_page" => 2, "total" => 3, "total_pages" => 2 }, json["meta"])
  end

  test "edita e apaga iniciativa com marcos e tarefas" do
    id = create_initiative["id"]
    create_task(id)

    patch api_v1_initiatives_initiative_path(id), as: :json, params: { initiative: { status: "active", sections: [] } }
    assert_response :ok
    assert_equal "active", json["status"]
    assert_equal [], json["sections"]

    delete api_v1_initiatives_initiative_path(id), as: :json
    assert_response :no_content
    assert_equal 0, ::Initiatives::Task.count

    get api_v1_initiatives_initiative_path(id)
    assert_response :not_found
    assert_equal "Registro não encontrado", json["error"]
  end

  # Tarefas

  test "cria tarefa só com o título, conclui e reabre" do
    id = create_initiative["id"]
    task = create_task(id, title: "Movimento do personagem")
    assert_equal "todo", task["status"]
    assert_nil task["completed_at"]

    patch api_v1_initiatives_task_path(task["id"]), as: :json, params: { task: { status: "done" } }
    assert_response :ok
    assert_not_nil json["completed_at"]

    patch api_v1_initiatives_task_path(task["id"]), as: :json, params: { task: { status: "todo" } }
    assert_nil json["completed_at"]
  end

  test "lista tarefas com filtros e busca" do
    id = create_initiative["id"]
    other = create_initiative["id"]
    post api_v1_initiatives_initiative_milestones_path(id), as: :json, params: { milestone: { title: "M" } }
    milestone_id = json["id"]
    doing = create_task(id, title: "Menu", status: "doing", milestone_id:)["id"]
    todo = create_task(id, title: "Movimento do personagem")["id"]
    create_task(other, title: "De outra iniciativa")

    get api_v1_initiatives_initiative_tasks_path(id)
    assert_response :ok
    assert_equal [ doing, todo ], json["data"].map { |t| t["id"] }
    assert_equal({ "total" => 2, "truncated" => false }, json["meta"])

    get api_v1_initiatives_initiative_tasks_path(id), params: { status: "todo" }
    assert_equal [ todo ], json["data"].map { |t| t["id"] }

    get api_v1_initiatives_initiative_tasks_path(id), params: { milestone_id: milestone_id }
    assert_equal [ doing ], json["data"].map { |t| t["id"] }

    get api_v1_initiatives_initiative_tasks_path(id), params: { milestone_id: "none" }
    assert_equal [ todo ], json["data"].map { |t| t["id"] }

    get api_v1_initiatives_initiative_tasks_path(id), params: { q: "sonag" }
    assert_equal [ todo ], json["data"].map { |t| t["id"] }
  end

  test "tarefa com marco de outra iniciativa ou título vazio retorna 422" do
    id = create_initiative["id"]
    foreign = ::Initiatives::Initiative.create!(name: "Outra").milestones.create!(title: "M")

    [ { title: "x", milestone_id: foreign.id }, { title: " " }, { title: "x", status: "blocked" } ].each do |attrs|
      post api_v1_initiatives_initiative_tasks_path(id), as: :json, params: { task: attrs }
      assert_response :unprocessable_entity, attrs.inspect
    end
  end

  test "apaga tarefa" do
    task = create_task(create_initiative["id"])
    delete api_v1_initiatives_task_path(task["id"]), as: :json
    assert_response :no_content
    assert_not ::Initiatives::Task.exists?(task["id"])
  end

  test "tarefas de iniciativa inexistente retornam 404" do
    get api_v1_initiatives_initiative_tasks_path(0)
    assert_response :not_found
  end

  # Marcos

  test "cria, lista com progresso, conclui e apaga marcos" do
    id = create_initiative["id"]
    post api_v1_initiatives_initiative_milestones_path(id), as: :json,
      params: { milestone: { title: "Protótipo", due_on: "2027-02-01" } }
    assert_response :created
    milestone = json
    assert_equal "2027-02-01", milestone["due_on"]
    assert_equal({ "done" => 0, "total" => 0 }, milestone["progress"])

    create_task(id, milestone_id: milestone["id"], status: "done")
    task = create_task(id, milestone_id: milestone["id"])

    get api_v1_initiatives_initiative_milestones_path(id)
    assert_response :ok
    assert_equal({ "done" => 1, "total" => 2 }, json["data"].first["progress"])

    patch api_v1_initiatives_milestone_path(milestone["id"]), as: :json, params: { milestone: { completed: true } }
    assert_response :ok
    assert_not_nil json["completed_at"]

    delete api_v1_initiatives_milestone_path(milestone["id"]), as: :json
    assert_response :no_content
    assert_nil ::Initiatives::Task.find(task["id"]).milestone_id
  end

  test "marco sem título retorna 422" do
    id = create_initiative["id"]
    post api_v1_initiatives_initiative_milestones_path(id), as: :json, params: { milestone: { title: "" } }
    assert_response :unprocessable_entity
    assert json.dig("fields", "title").any?
  end
end
