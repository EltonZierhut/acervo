require_relative "test_helper"

class AgentTest < Minitest::Test
  include TestSupport

  Workspace = Struct.new(:root, :repo_dir, :attachments_dir)
  SLOW = 'if [ "$1" = kill ]; then exit 0; fi; exec sleep 0.3'.freeze

  def agent(cfg = config) = AcervoExecutor::Agent.new(cfg, quiet_log)

  def args(cfg = config)
    agent(cfg).docker_args(run_id: 7, repository: "a/b", workspace: Workspace.new("/t", "/t/repo", "/t/att"))
  end

  def test_container_sem_credenciais_do_github_nem_pastas_do_usuario
    line = args.join(" ")
    refute_match(/GH_TOKEN|GITHUB_TOKEN|\.ssh|\.config|docker\.sock/, line)
    refute_includes line, Dir.home
    assert_includes line, "--cap-drop ALL"
    assert_includes line, "no-new-privileges"
  end

  def test_git_somente_leitura_e_anexos_somente_leitura
    line = args.join(" ")
    assert_includes line, "type=bind,src=/t/repo/.git,dst=/workspace/.git,readonly"
    assert_includes line, "type=bind,src=/t/att,dst=/attachments,readonly"
  end

  def test_token_do_claude_nao_aparece_na_linha_de_comando
    refute_includes args.join(" "), "tok-claude"
    assert_includes args, "CLAUDE_CODE_OAUTH_TOKEN"
  end

  def test_limite_de_gasto_e_imagem
    assert_includes args(config("max_budget_usd" => 5, "image" => "x:1")), "--max-budget-usd"
    assert_includes args(config("image" => "x:1")), "x:1"
    refute_includes args, "--max-budget-usd"
  end

  def test_le_o_resultado_estruturado
    data = { "outcome" => "completed", "summary" => "ok" }
    assert_equal data, agent.parse(JSON.generate("structured_output" => data)).data
    assert_equal data, agent.parse(JSON.generate("result" => JSON.generate(data))).data
  end

  def test_resultado_fora_do_formato_vira_falha
    [ "lixo", JSON.generate("result" => "texto"), JSON.generate("structured_output" => { "outcome" => "x" }),
      JSON.generate("is_error" => true, "result" => "limite") ].each do |output|
      assert_equal :failed, agent.parse(output).state, output
    end
  end

  # "docker" falso no PATH para exercitar o controle do processo.
  def with_fake_docker(script)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "docker"), "#!/bin/sh\n#{script}\n")
      File.chmod(0o755, File.join(dir, "docker"))
      old = ENV["PATH"]
      ENV["PATH"] = "#{dir}:#{old}"
      begin
        root = File.join(dir, "w")
        FileUtils.mkdir_p(root)
        yield Workspace.new(root, "/r", "/a")
      ensure
        ENV["PATH"] = old
      end
    end
  end

  def fast(**options) = AcervoExecutor::Agent.new(config, quiet_log, poll: 0.01, heartbeat_every: 0.02, **options)

  def execute(instance, workspace, should_stop: -> { false }, &block)
    instance.run(run_id: 1, repository: "a/b", workspace:, prompt: "p", should_stop:, &(block || -> { false }))
  end

  def test_termina_normalmente
    with_fake_docker(%(cat >/dev/null; echo '{"structured_output":{"outcome":"no_changes","summary":"s"}}')) do |ws|
      outcome = execute(fast, ws)
      assert_equal :finished, outcome.state
      assert_equal "no_changes", outcome.data["outcome"]
    end
  end

  def test_erro_do_agente_oculta_credenciais
    with_fake_docker("echo erro tok-claude >&2; exit 3") do |ws|
      outcome = execute(fast, ws)
      assert_equal :failed, outcome.state
      refute_includes outcome.error, "tok-claude"
    end
  end

  def test_cancelamento_interrompe
    with_fake_docker(SLOW) do |ws|
      assert_equal :canceled, execute(fast, ws) { true }.state
    end
  end

  def test_limite_de_tempo_interrompe
    with_fake_docker(SLOW) do |ws|
      assert_equal :timeout, execute(fast(time_limit: 0.03), ws).state
    end
  end

  def test_encerramento_do_executor_interrompe
    with_fake_docker(SLOW) do |ws|
      assert_equal :interrupted, execute(fast, ws, should_stop: -> { true }).state
    end
  end
end
