require "test_helper"

class Initiatives::RunTest < ActiveSupport::TestCase
  Run = Initiatives::Run

  setup do
    @initiative = Initiatives::Initiative.create!(name: "I", github_repository: "owner/name")
    @task = task("Primeira")
  end

  def task(title, initiative: @initiative) = initiative.tasks.create!(title:, description: "Faça")

  def enqueue(task = @task) = Run.enqueue(task).tap { |run| assert run.persisted?, run.errors.full_messages.join }

  def url(number = 1) = "https://github.com/owner/name/pull/#{number}"

  test "copia o repositório ao entrar na fila" do
    run = enqueue
    @initiative.update!(github_repository: "owner/outro")
    assert_equal "owner/name", run.reload.repository
  end

  test "recusa sem descrição, sem repositório, com acesso inválido, concluída ou já ativa" do
    @task.update!(description: nil)
    assert_not Run.enqueue(@task).persisted?
    @task.update!(description: "x")

    @initiative.update!(github_repository: nil)
    assert_not Run.enqueue(@task.reload).persisted?

    @initiative.update!(github_repository: "owner/name")
    @initiative.update!(repository_status: :invalid)
    assert_not Run.enqueue(@task.reload).persisted?
    @initiative.update!(repository_status: :valid)

    enqueue(@task.reload)
    assert_not Run.enqueue(@task).persisted?

    other = task("Concluída")
    other.update!(status: :done)
    assert_not Run.enqueue(other).persisted?
  end

  test "o índice impede duas ativas na mesma tarefa" do
    enqueue
    assert_raises(ActiveRecord::RecordNotUnique) do
      Run.new(task: @task, repository: "a/b", enqueued_at: Time.current).save!(validate: false)
    end
  end

  test "claim respeita a ordem de chegada e uma por vez" do
    first = enqueue
    second = enqueue(task("Segunda"))
    assert_equal first, Run.claim
    assert first.reload.running?
    assert_nil Run.claim
    first.complete!(status: "no_changes", summary: "nada")
    assert_equal second, Run.claim
  end

  test "claim sem fila devolve nil" do
    assert_nil Run.claim
  end

  test "pergunta libera a fila e a resposta devolve na posição original" do
    first = enqueue
    second = enqueue(task("Segunda"))
    third = enqueue(task("Terceira"))
    Run.claim
    first.ask!([ "Qual tela?", "Qual cor?" ])
    assert first.reload.waiting?

    assert_equal second, Run.claim
    original = first.enqueued_at
    question_ids = first.questions.ordered.pluck(:id)

    first.answer!([ [ question_ids[0], "Login" ] ])
    assert first.reload.waiting?, "ainda falta uma resposta"
    first.answer!([ [ question_ids[1], "Azul" ] ])
    assert first.reload.queued?
    assert_equal original, first.enqueued_at
    assert_nil first.started_at

    second.complete!(status: "no_changes")
    assert_equal first, Run.claim
    first.complete!(status: "no_changes")
    assert_equal third, Run.claim
  end

  test "resposta vazia é recusada e nada é gravado" do
    run = enqueue
    Run.claim
    run.ask!([ "Qual?" ])
    question = run.questions.first
    assert_raises(ArgumentError) { run.answer!([ [ question.id, "  " ] ]) }
    assert_nil question.reload.answered_at
  end

  test "só aceita perguntas em andamento e respostas em espera" do
    run = enqueue
    assert_raises(Run::InvalidTransition) { run.ask!([ "x" ]) }
    assert_raises(Run::InvalidTransition) { run.answer!([]) }
  end

  test "pr_open guarda o link e leva a tarefa de a fazer para fazendo" do
    run = enqueue
    Run.claim
    run.complete!(status: "pr_open", summary: "feito", branch: "b", pull_request_url: url)
    assert run.reload.pr_open?
    assert run.finished_at
    assert @task.reload.doing?
  end

  test "pr_open não reabre tarefa concluída nem altera outro status" do
    run = enqueue
    Run.claim
    @task.update!(status: :done)
    run.complete!(status: "pr_open", pull_request_url: url)
    assert @task.reload.done?
  end

  test "recusa link de outro repositório" do
    run = enqueue
    Run.claim
    assert_raises(ArgumentError) { run.complete!(status: "pr_open", pull_request_url: "https://github.com/outro/repo/pull/1") }
    assert_raises(ArgumentError) { run.complete!(status: "pr_open") }
    assert_raises(ArgumentError) { run.complete!(status: "pr_open", pull_request_url: "#{url}/../../x") }
  end

  test "recusa resultado desconhecido" do
    run = enqueue
    Run.claim
    assert_raises(ArgumentError) { run.complete!(status: "queued") }
  end

  test "complete é idempotente" do
    run = enqueue
    Run.claim
    2.times { run.complete!(status: "pr_open", pull_request_url: url) }
    assert run.reload.pr_open?
  end

  test "complete fora de execução é recusado" do
    run = enqueue
    assert_raises(Run::InvalidTransition) { run.complete!(status: "no_changes") }
  end

  test "falha guarda tipo e motivo, com valores padrão" do
    run = enqueue
    Run.claim
    run.complete!(status: "failed", failure_kind: "timeout", failure_reason: "Passou de 60 min")
    assert_equal "timeout", run.reload.failure_kind

    other = enqueue(task("Outra"))
    Run.claim
    other.complete!(status: "failed")
    assert_equal "other", other.reload.failure_kind
    assert other.failure_reason.present?
  end

  test "cancelar vale para fila, andamento e espera, não para estado final" do
    queued = enqueue
    assert queued.cancel!
    assert queued.reload.canceled?
    assert_not queued.cancel!

    running = enqueue(task("B"))
    Run.claim
    assert_not running.reload.heartbeat!
    assert running.cancel!
    assert running.reload.heartbeat!, "o heartbeat manda parar"

    waiting = enqueue(task("C"))
    Run.claim
    waiting.ask!([ "?" ])
    assert waiting.cancel!
  end

  test "resultado depois de cancelar não muda o estado, mas guarda o PR" do
    run = enqueue
    Run.claim
    run.cancel!
    run.complete!(status: "pr_open", pull_request_url: url, branch: "b")
    assert run.reload.canceled?
    assert_equal url, run.pull_request_url
    assert @task.reload.todo?
  end

  test "sem heartbeat por 5 min vira falha por interrupção, e o claim segue" do
    run = enqueue
    other = enqueue(task("Outra"))
    Run.claim
    run.update!(last_heartbeat_at: 6.minutes.ago)
    assert_equal other, Run.claim
    assert run.reload.failed?
    assert_equal "interrupted", run.failure_kind
  end

  test "heartbeat recente mantém em andamento" do
    run = enqueue
    Run.claim
    run.reload.update!(last_heartbeat_at: 4.minutes.ago)
    assert_not run.heartbeat!
    Run.expire_stale!
    assert run.reload.running?
  end

  test "PR que chega depois da interrupção corrige o resultado" do
    run = enqueue
    Run.claim
    run.update!(last_heartbeat_at: 6.minutes.ago)
    Run.expire_stale!
    run.reload.complete!(status: "pr_open", pull_request_url: url)
    assert run.reload.pr_open?
    assert_nil run.failure_kind
  end

  test "concluir a tarefa à mão cancela fila e espera, mas não o que está rodando" do
    queued = enqueue
    @task.update!(status: :done)
    assert queued.reload.canceled?

    other = task("B")
    running = enqueue(other)
    Run.claim
    other.update!(status: :done)
    assert running.reload.running?
  end

  test "reenviar cria outra execução e guarda o histórico" do
    first = enqueue
    Run.claim
    first.complete!(status: "failed")
    second = enqueue
    assert_equal 2, @task.runs.count
    assert_equal second, Run.latest_by_task([ @task.id ])[@task.id]
  end

  test "apagar a tarefa apaga as execuções" do
    run = enqueue
    Run.claim
    run.ask!([ "?" ])
    assert_difference([ "Run.count", "Initiatives::RunQuestion.count" ], -1) { @task.destroy }
  end
end
