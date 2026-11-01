require "test_helper"

class InitiativesAutomationApiTest < ActionDispatch::IntegrationTest
  BASE = "/api/v1/initiatives".freeze
  PNG = "\x89PNG\r\n\x1A\n".b + "x".b * 20

  setup do
    sign_in_as users(:owner)
    @initiative = Initiatives::Initiative.create!(name: "Jogo", github_repository: "owner/name")
    @task = @initiative.tasks.create!(title: "Corrigir", description: "Detalhes")
  end

  def upload(body = PNG, type: "image/png", filename: "tela.png")
    post "#{BASE}/tasks/#{@task.id}/task_images?filename=#{filename}", params: body, headers: { "CONTENT_TYPE" => type }
  end

  # Imagens

  test "envia, lista, entrega e apaga imagem" do
    upload
    assert_response :created
    image = json
    assert_equal "image/png", image["content_type"]
    assert_nil image["data"]

    get "#{BASE}/tasks/#{@task.id}/task_images"
    assert_equal [ image["id"] ], json.map { |i| i["id"] }

    get image["url"]
    assert_response :ok
    assert_equal PNG, response.body.b
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_includes response.headers["Cache-Control"], "private"
    assert_includes response.headers["Content-Security-Policy"], "sandbox"

    delete image["url"], as: :json
    assert_response :no_content
  end

  test "recusa outros tipos de conteúdo no envio" do
    upload("x", type: "text/plain")
    assert_response :unsupported_media_type
    upload("x", type: "multipart/form-data; boundary=x")
    assert_includes [ 400, 415 ], response.status
    assert_equal 0, @task.images.count
  end

  test "imagem falsa é recusada com 422" do
    upload("<svg/>", type: "image/svg+xml")
    assert_response :unprocessable_entity
    assert json["errors"].any?
  end

  test "imagem grande demais é recusada" do
    upload(PNG + "x".b * (10.megabytes + 1))
    assert_response :unprocessable_entity
  end

  test "outras rotas continuam exigindo JSON" do
    post "#{BASE}/tasks/#{@task.id}/task_links", params: "x", headers: { "CONTENT_TYPE" => "image/png" }
    assert_response :unsupported_media_type
  end

  # Links

  test "cria, altera e apaga link" do
    post "#{BASE}/tasks/#{@task.id}/task_links", params: { task_link: { url: "https://e.com", title: "Doc" } }, as: :json
    assert_response :created
    id = json["id"]

    patch "#{BASE}/task_links/#{id}", params: { task_link: { title: "Outro" } }, as: :json
    assert_equal "Outro", json["title"]

    post "#{BASE}/tasks/#{@task.id}/task_links", params: { task_link: { url: "javascript:alert(1)" } }, as: :json
    assert_response :unprocessable_entity

    delete "#{BASE}/task_links/#{id}", as: :json
    assert_response :no_content
  end

  test "o JSON da tarefa traz contagens e última execução" do
    upload
    post "#{BASE}/tasks/#{@task.id}/runs", as: :json
    get "#{BASE}/initiatives/#{@initiative.id}/tasks"
    task = json["data"].first
    assert_equal 1, task["images_count"]
    assert_equal 0, task["links_count"]
    assert_equal "queued", task["latest_run"]["status"]
  end

  # Repositório

  test "conecta, normaliza e pede nova verificação" do
    patch "#{BASE}/initiatives/#{@initiative.id}",
      params: { initiative: { github_repository: "https://github.com/a/b.git" } }, as: :json
    assert_equal "a/b", json["github_repository"]
    assert_equal "unverified", json["repository_status"]

    @initiative.reload.update!(repository_status: :invalid, repository_error: "x")
    post "#{BASE}/initiatives/#{@initiative.id}/verify_repository", as: :json
    assert_equal "unverified", json["repository_status"]
    assert_nil json["repository_error"]

    @initiative.update!(github_repository: nil)
    post "#{BASE}/initiatives/#{@initiative.id}/verify_repository", as: :json
    assert_response :unprocessable_entity
  end

  test "repositório inválido é recusado" do
    patch "#{BASE}/initiatives/#{@initiative.id}", params: { initiative: { github_repository: "nao valido" } }, as: :json
    assert_response :unprocessable_entity
    assert json["fields"]["github_repository"]
  end

  # Fila

  test "envia para a fila, lista, busca, filtra e cancela" do
    post "#{BASE}/tasks/#{@task.id}/runs", as: :json
    assert_response :created
    run = json
    assert_equal "queued", run["status"]
    assert_equal "Corrigir", run["task_title"]
    assert_equal "Jogo", run["initiative_name"]

    post "#{BASE}/tasks/#{@task.id}/runs", as: :json
    assert_response :unprocessable_entity

    get "#{BASE}/runs"
    assert_equal [ run["id"] ], json["data"].map { |r| r["id"] }
    assert_equal 1, json["meta"]["total"]

    get "#{BASE}/runs", params: { q: "Corr" }
    assert_equal 1, json["data"].size
    get "#{BASE}/runs", params: { q: "inexistente" }
    assert_empty json["data"]
    get "#{BASE}/runs", params: { status: "failed" }
    assert_empty json["data"]

    post "#{BASE}/runs/#{run['id']}/cancel", as: :json
    assert_equal "canceled", json["status"]
    post "#{BASE}/runs/#{run['id']}/cancel", as: :json
    assert_response :unprocessable_entity

    get "#{BASE}/tasks/#{@task.id}/runs"
    assert_equal 1, json.size
  end

  test "responde às perguntas e devolve para a fila" do
    run = Initiatives::Run.enqueue(@task)
    Initiatives::Run.claim
    run.ask!([ "Qual tela?" ])
    question = run.questions.first

    post "#{BASE}/runs/#{run.id}/answers", params: { answers: [] }, as: :json
    assert_response :unprocessable_entity
    post "#{BASE}/runs/#{run.id}/answers", params: { answers: [ { question_id: question.id, answer: "" } ] }, as: :json
    assert_response :unprocessable_entity

    post "#{BASE}/runs/#{run.id}/answers", params: { answers: [ { question_id: question.id, answer: "Login" } ] }, as: :json
    assert_response :ok
    assert_equal "queued", json["status"]
    assert_equal "Login", json["questions"].first["answer"]

    post "#{BASE}/runs/#{run.id}/answers", params: { answers: [ { question_id: question.id, answer: "Outra" } ] }, as: :json
    assert_response :unprocessable_entity
  end

  test "situação do executor" do
    get "#{BASE}/executor_status"
    assert_equal false, json["configured"]
    Initiatives::Executor.rotate_token!
    Initiatives::Executor.first.update!(last_seen_at: Time.current)
    get "#{BASE}/executor_status"
    assert_equal true, json["available"]
    assert_nil json["token_digest"]
  end
end
