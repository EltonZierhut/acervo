require_relative "test_helper"

class LoopTest < Minitest::Test
  include TestSupport

  RUN = { "id" => 7, "repository" => "a/b", "task" => { "id" => 3, "title" => "T", "description" => "D" } }.freeze

  class FakeClient
    attr_reader :completed, :asked
    attr_accessor :pending_run, :complete_error, :claim_error

    def initialize
      @completed = []
      @asked = []
    end

    def claim
      raise claim_error if claim_error

      pending_run.tap { self.pending_run = nil }
    end

    def complete(run_id, result)
      raise complete_error if complete_error

      @completed << [ run_id.to_s, result ]
    end

    def ask(run_id, questions) = @asked << [ run_id, questions ]
    def heartbeat(_id) = false
    def repository_checks = []
    def download_image(_id) = "x"
  end

  class FakeWorkspace
    class << self
      attr_accessor :clone_error
    end

    def self.open
      yield new
    end

    def clone(_repo)
      raise AcervoExecutor::Error, self.class.clone_error if self.class.clone_error
    end

    def save_images(_images, _client) = []
    def pr_template = nil
  end

  FakeAgent = Struct.new(:outcome) do
    def run(**) = outcome
  end

  FakePublisher = Struct.new(:result, :error) do
    def publish(**)
      raise error if error

      result
    end
  end

  NullChecker = Class.new { def run; end }

  def outcome(state, data: nil, error: nil) = AcervoExecutor::Agent::Outcome.new(state:, data:, error:)

  def build(agent_outcome, publisher: FakePublisher.new, client: FakeClient.new, dir: Dir.mktmpdir)
    FakeWorkspace.clone_error = nil
    log = quiet_log
    client.pending_run ||= RUN
    [
      AcervoExecutor::Loop.new(config: config, client:, log:, agent: FakeAgent.new(agent_outcome), publisher:,
                               spool: AcervoExecutor::Spool.new(client, log, dir:), checker: NullChecker.new,
                               workspace_class: FakeWorkspace),
      client
    ]
  end

  def finished(outcome_name, **extra) = outcome(:finished, data: { "outcome" => outcome_name, "summary" => "S", **extra })

  def result_of(client) = client.completed.first.last.transform_keys(&:to_s)

  def test_pr_aberto
    loop, client = build(finished("completed"), publisher: FakePublisher.new({ branch: "b", pull_request_url: "u" }))
    assert loop.tick
    result = result_of(client)
    assert_equal "pr_open", result["status"]
    assert_equal "u", result["pull_request_url"]
  end

  def test_agente_diz_concluido_mas_nada_mudou
    loop, client = build(finished("completed"))
    loop.tick
    assert_equal "no_changes", result_of(client)["status"]
  end

  def test_sem_alteracoes_nao_chama_o_publicador
    publisher = FakePublisher.new(nil, RuntimeError.new("não deveria publicar"))
    loop, client = build(finished("no_changes"), publisher:)
    loop.tick
    assert_equal "no_changes", result_of(client)["status"]
  end

  def test_perguntas_vao_para_o_acervo_sem_resultado_final
    publisher = FakePublisher.new(nil, RuntimeError.new("não deveria publicar"))
    loop, client = build(finished("needs_input", "questions" => [ "Qual?" ]), publisher:)
    loop.tick
    assert_equal [ [ 7, [ "Qual?" ] ] ], client.asked
    assert_empty client.completed
  end

  def test_needs_input_sem_perguntas_vira_falha
    loop, client = build(finished("needs_input"))
    loop.tick
    assert_equal "agent", result_of(client)["failure_kind"]
  end

  def test_cancelada_nao_informa_resultado
    loop, client = build(outcome(:canceled))
    loop.tick
    assert_empty client.completed
  end

  def test_tempo_limite_interrupcao_e_erro_do_agente
    { timeout: "timeout", interrupted: "interrupted", failed: "agent" }.each do |state, kind|
      loop, client = build(outcome(state, error: "x"))
      loop.tick
      assert_equal kind, result_of(client)["failure_kind"]
    end
  end

  def test_alteracao_em_workflow_vira_falha_propria
    publisher = FakePublisher.new(nil, AcervoExecutor::Publisher::WorkflowChange.new("workflows"))
    loop, client = build(finished("completed"), publisher:)
    loop.tick
    assert_equal "workflow_change", result_of(client)["failure_kind"]
  end

  def test_erro_no_clone_vira_falha_de_repositorio
    loop, client = build(finished("completed"))
    FakeWorkspace.clone_error = "Sem acesso"
    loop.tick
    assert_equal "repository", result_of(client)["failure_kind"]
    assert_equal "Sem acesso", result_of(client)["failure_reason"]
  end

  def test_erro_inesperado_nao_derruba_o_executor
    loop, client = build(finished("completed"), publisher: FakePublisher.new(nil, RuntimeError.new("tok-claude")))
    assert loop.tick
    result = result_of(client)
    assert_equal "other", result["failure_kind"]
    refute_includes result["failure_reason"], "tok-claude"
  end

  def test_fila_vazia
    client = FakeClient.new
    log = quiet_log
    loop = AcervoExecutor::Loop.new(config: config, client:, log:, agent: nil, publisher: nil,
                                    spool: AcervoExecutor::Spool.new(client, log, dir: Dir.mktmpdir), checker: NullChecker.new)
    refute loop.tick
  end

  def test_sem_conexao_continua_vivo
    client = FakeClient.new
    client.claim_error = AcervoExecutor::Client::Unavailable.new("fora do ar")
    loop, = build(nil, client:)
    client.pending_run = nil
    refute loop.tick
  end

  def test_resultado_sobrevive_a_queda_e_e_entregue_depois_sem_nova_tarefa
    dir = Dir.mktmpdir
    client = FakeClient.new
    client.complete_error = AcervoExecutor::Client::Unavailable.new("fora do ar")
    loop, = build(finished("completed"), publisher: FakePublisher.new({ branch: "b", pull_request_url: "u" }), client:, dir:)
    assert loop.tick
    assert_empty client.completed
    assert_equal 1, Dir[File.join(dir, "*.json")].size

    client.pending_run = RUN
    refute loop.tick, "não pega outra tarefa com resultado pendente"
    assert_equal RUN, client.pending_run

    client.complete_error = nil
    loop.tick
    assert_equal "pr_open", client.completed.first.last["status"]
    assert_empty Dir[File.join(dir, "*.json")]
  end

  def test_recusa_definitiva_descarta_o_resultado_pendente
    dir = Dir.mktmpdir
    client = FakeClient.new
    client.complete_error = AcervoExecutor::Client::Rejected.new(404, "não existe")
    loop, = build(finished("no_changes"), client:, dir:)
    loop.tick
    assert_empty Dir[File.join(dir, "*.json")]
  end

  def test_token_invalido_para_o_executor
    client = FakeClient.new
    client.claim_error = AcervoExecutor::Client::Rejected.new(401, "Token inválido")
    loop, = build(nil, client:)
    assert_raises(AcervoExecutor::Client::Rejected) { loop.tick }
  end
end
