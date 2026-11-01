require "test_helper"

class InitiativesExecutorApiTest < ActionDispatch::IntegrationTest
  BASE = "/api/v1/initiatives/executor".freeze
  PNG = "\x89PNG\r\n\x1A\n".b + "x".b * 20

  setup do
    @token = Initiatives::Executor.rotate_token!
    @initiative = Initiatives::Initiative.create!(name: "Jogo", github_repository: "owner/name")
    @task = @initiative.tasks.create!(title: "Corrigir", description: "Detalhes")
  end

  def auth = { "Authorization" => "Bearer #{@token}" }

  def call(path, params = {}) = post("#{BASE}#{path}", params:, headers: auth, as: :json)

  def claimed
    Initiatives::Run.enqueue(@task).tap { Initiatives::Run.claim }
  end

  test "exige o token e não aceita a sessão do navegador" do
    post "#{BASE}/claim", as: :json
    assert_response :unauthorized

    post "#{BASE}/claim", headers: { "Authorization" => "Bearer errado" }, as: :json
    assert_response :unauthorized

    sign_in_as users(:owner)
    post "#{BASE}/claim", as: :json
    assert_response :unauthorized
  end

  test "o token do executor não abre as demais rotas" do
    get "/api/v1/initiatives/initiatives", headers: auth
    assert_response :unauthorized
  end

  test "claim sem trabalho responde 204 e registra a presença" do
    call "/claim", version: "1.0.0"
    assert_response :no_content
    executor = Initiatives::Executor.first
    assert executor.available?
    assert_equal "1.0.0", executor.version
  end

  test "claim entrega o conteúdo atual da tarefa" do
    Initiatives::Run.enqueue(@task)
    @task.update!(description: "Editada na fila")
    @task.links.create!(url: "https://e.com", title: "Doc")
    image = Initiatives::TaskImage.attach(@task, filename: "a.png", data: PNG)

    call "/claim"
    assert_response :ok
    run = json["run"]
    assert_equal "owner/name", run["repository"]
    assert_equal "Editada na fila", run["task"]["description"]
    assert_equal @initiative.id, run["task"]["initiative_id"]
    assert_equal [ "https://e.com" ], run["links"].map { |l| l["url"] }
    assert_equal [ image.id ], run["images"].map { |i| i["id"] }
    assert_nil run["images"].first["data"]
  end

  test "claim com outra em andamento responde 204" do
    claimed
    call "/claim"
    assert_response :no_content
  end

  test "imagem só para tarefa em andamento" do
    image = Initiatives::TaskImage.attach(@task, filename: "a.png", data: PNG)
    get "#{BASE}/images/#{image.id}", headers: auth
    assert_response :not_found

    claimed
    get "#{BASE}/images/#{image.id}", headers: auth
    assert_response :ok
    assert_equal PNG, response.body.b
  end

  test "heartbeat informa cancelamento" do
    run = claimed
    call "/runs/#{run.id}/heartbeat"
    assert_equal false, json["cancel"]
    run.cancel!
    call "/runs/#{run.id}/heartbeat"
    assert_equal true, json["cancel"]
  end

  test "heartbeat de tarefa apagada responde 404" do
    run = claimed
    @task.destroy
    call "/runs/#{run.id}/heartbeat"
    assert_response :not_found
  end

  test "perguntas colocam em espera" do
    run = claimed
    call "/runs/#{run.id}/questions", questions: [ " " ]
    assert_response :unprocessable_entity

    call "/runs/#{run.id}/questions", questions: [ "Qual tela?" ]
    assert_response :ok
    assert run.reload.waiting?

    call "/runs/#{run.id}/questions", questions: [ "De novo?" ]
    assert_response :conflict
  end

  test "complete registra o PR e é idempotente" do
    run = claimed
    params = { status: "pr_open", summary: "Feito", branch: "acervo/x", pull_request_url: "https://github.com/owner/name/pull/3" }
    2.times do
      call "/runs/#{run.id}/complete", params
      assert_response :ok
    end
    assert_equal "Feito", run.reload.summary
    assert @task.reload.doing?
  end

  test "complete recusa PR de outro repositório e resultado inválido" do
    run = claimed
    call "/runs/#{run.id}/complete", status: "pr_open", pull_request_url: "https://github.com/x/y/pull/3"
    assert_response :unprocessable_entity
    call "/runs/#{run.id}/complete", status: "queued"
    assert_response :unprocessable_entity
    assert run.reload.running?
  end

  test "complete fora de andamento responde 409" do
    run = Initiatives::Run.enqueue(@task)
    call "/runs/#{run.id}/complete", status: "no_changes"
    assert_response :conflict
  end

  test "verificação de repositórios atualiza todas as iniciativas dele" do
    other = Initiatives::Initiative.create!(name: "Outra", github_repository: "owner/name")
    Initiatives::Initiative.create!(name: "Sem", github_repository: nil)

    get "#{BASE}/repository_checks", headers: auth
    assert_equal [ "owner/name" ], json["repositories"]

    call "/repository_checks", repository: "owner/name", valid: false, error: "Sem acesso"
    assert_response :ok
    assert other.reload.repository_invalid?
    assert_equal "Sem acesso", other.repository_error

    call "/repository_checks", repository: "owner/name", valid: true
    assert @initiative.reload.repository_valid?
    assert_nil @initiative.repository_error

    get "#{BASE}/repository_checks", headers: auth
    assert_empty json["repositories"]
  end
end
