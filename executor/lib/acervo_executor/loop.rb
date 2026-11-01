module AcervoExecutor
  # Busca a fila, executa uma tarefa por vez e informa o resultado.
  class Loop
    IDLE_SECONDS = 30

    def initialize(config:, client:, log:, agent:, publisher:, spool:, checker:, workspace_class: Workspace)
      @config = config
      @client = client
      @log = log
      @agent = agent
      @publisher = publisher
      @spool = spool
      @checker = checker
      @workspace_class = workspace_class
      @stopping = false
    end

    def stop! = @stopping = true

    def run_forever
      @log.info("Executor iniciado. Ctrl+C encerra.")
      until @stopping
        worked = tick
        sleep_idle unless worked
      end
      @log.info("Executor encerrado.")
    end

    # Devolve true se executou uma tarefa.
    def tick
      return false unless @spool.flush

      @checker.run
      run = @client.claim
      return false unless run

      process(run)
      true
    rescue Client::Unavailable => e
      @log.info(e.message)
      false
    rescue Client::Rejected => e
      raise if e.status == 401

      @log.info(e.message)
      false
    end

    def process(run)
      @log.to_file(File.join(Config.state_dir, "runs", "#{Integer(run['id'])}.log")) do
        @log.info("Execução #{run['id']}: #{run['repository']}, tarefa #{run.dig('task', 'id')}")
        result = develop(run)
        report(run, result) if result
      end
    end

    private

    def report(run, result)
      @log.info("Execução #{run['id']}: #{result[:status]}")
      @spool.deliver(run["id"], result)
    end

    # Devolve o resultado a informar, ou nil quando não há o que informar (espera ou cancelamento).
    def develop(run)
      @workspace_class.open do |workspace|
        workspace.clone(run["repository"])
        image_paths = workspace.save_images(run.fetch("images", []), @client)
        prompt = Prompt.render(run, image_paths:, pr_template: workspace.pr_template)

        outcome = @agent.run(run_id: run["id"], repository: run["repository"], workspace:, prompt:,
                             should_stop: -> { @stopping }) { heartbeat(run["id"]) }
        conclude(run, workspace, outcome)
      end
    rescue Publisher::WorkflowChange => e
      failure("workflow_change", e.message)
    rescue Client::Rejected => e
      raise if e.status == 401

      failure("other", e.message)
    rescue Client::Unavailable
      failure("other", "O Acervo ficou indisponível durante o preparo da execução.")
    rescue Error => e
      failure("repository", @log.scrub(e.message))
    rescue StandardError => e
      @log.info("Erro inesperado: #{e.class}: #{e.message}")
      failure("other", "Erro inesperado no executor (#{e.class}).")
    end

    def heartbeat(run_id)
      @client.heartbeat(run_id)
    rescue Client::Unavailable
      false # Uma queda de rede não interrompe o trabalho.
    end

    def conclude(run, workspace, outcome)
      case outcome.state
      when :canceled
        @log.info("Execução #{run['id']}: cancelada")
        nil
      when :timeout then failure("timeout", "A execução passou do limite de 60 minutos e foi interrompida.")
      when :interrupted then failure("interrupted", "O executor foi encerrado durante a execução. Envie a tarefa de novo.")
      when :failed then failure("agent", outcome.error)
      else finish(run, workspace, outcome.data)
      end
    end

    def finish(run, workspace, data)
      return ask(run, data) if data["outcome"] == "needs_input"

      summary = data["summary"].to_s
      return { status: "no_changes", summary: } if data["outcome"] == "no_changes"

      published = @publisher.publish(run:, workspace:, data:)
      return { status: "no_changes", summary: } unless published

      { status: "pr_open", summary:, **published }
    end

    def ask(run, data)
      questions = Array(data["questions"]).map { |q| q.to_s.strip }.reject(&:empty?)
      return failure("agent", "O agente disse que faltava informação, mas não fez perguntas.") if questions.empty?

      @client.ask(run["id"], questions)
      @log.info("Execução #{run['id']}: aguardando resposta")
      nil
    end

    def failure(kind, reason) = { status: "failed", failure_kind: kind, failure_reason: reason.to_s[0, 1_000] }

    def sleep_idle
      IDLE_SECONDS.times do
        break if @stopping

        sleep 1
      end
    end
  end
end
