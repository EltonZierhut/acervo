module AcervoExecutor
  # Roda o Claude Code num container descartável, sem credenciais do GitHub e sem pastas do usuário.
  # O .git fica só para leitura, para o agente não criar hooks nem mudar a configuração que o Git
  # da máquina usará depois.
  class Agent
    TIME_LIMIT = 60 * 60
    HEARTBEAT_EVERY = 30
    Outcome = Struct.new(:state, :data, :error, keyword_init: true)

    SCHEMA = {
      type: "object",
      properties: {
        outcome: { type: "string", enum: %w[completed needs_input no_changes] },
        summary: { type: "string" },
        pr_title: { type: "string" },
        pr_body: { type: "string" },
        decisions: { type: "array", items: { type: "string" } },
        unread_links: { type: "array", items: { type: "string" } },
        tests: { type: "string" },
        questions: { type: "array", items: { type: "string" } }
      },
      required: %w[outcome summary],
      additionalProperties: false
    }.freeze

    def initialize(config, log, time_limit: TIME_LIMIT, heartbeat_every: HEARTBEAT_EVERY, poll: 1)
      @config = config
      @log = log
      @time_limit = time_limit
      @heartbeat_every = heartbeat_every
      @poll = poll
    end

    def docker_args(run_id:, repository:, workspace:)
      uid = Process.uid
      gid = Process.gid
      args = [
        "docker", "run", "--rm", "-i", "--name", container_name(run_id),
        "--user", "#{uid}:#{gid}",
        "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
        "--pids-limit", "2048",
        "--tmpfs", "/home/agent:uid=#{uid},gid=#{gid},mode=700,size=2g",
        "--mount", "type=bind,src=#{workspace.repo_dir},dst=/workspace",
        "--mount", "type=bind,src=#{File.join(workspace.repo_dir, '.git')},dst=/workspace/.git,readonly",
        "--mount", "type=bind,src=#{workspace.attachments_dir},dst=/attachments,readonly",
        # Sem valor na linha: o token vem do ambiente, para não aparecer na lista de processos.
        "-e", "CLAUDE_CODE_OAUTH_TOKEN",
        "-w", "/workspace",
        @config.image_for(repository),
        "claude", "-p", "--output-format", "json", "--json-schema", JSON.generate(SCHEMA),
        "--dangerously-skip-permissions", "--no-session-persistence"
      ]
      args += [ "--max-budget-usd", @config.max_budget_usd.to_s ] if @config.max_budget_usd
      args
    end

    # O bloco roda a cada heartbeat e devolve true para cancelar. should_stop indica Ctrl+C.
    def run(run_id:, repository:, workspace:, prompt:, should_stop: -> { false })
      prompt_file = File.join(workspace.root, "prompt.md")
      out_file = File.join(workspace.root, "agent.out")
      err_file = File.join(workspace.root, "agent.err")
      File.write(prompt_file, prompt)

      pid = Process.spawn({ "CLAUDE_CODE_OAUTH_TOKEN" => @config.claude_oauth_token },
                          *docker_args(run_id:, repository:, workspace:), in: prompt_file, out: out_file, err: err_file)
      stop = wait(pid, should_stop) { yield }
      if stop
        kill(run_id)
        Process.wait(pid)
        return Outcome.new(state: stop)
      end

      return failed("O agente terminou com erro: #{tail(err_file, out_file)}") unless $?.success?

      parse(File.read(out_file))
    end

    def parse(output)
      envelope = JSON.parse(output)
      return failed("O agente informou erro: #{envelope['result'].to_s[0, 500]}") if envelope["is_error"]

      data = envelope["structured_output"] || JSON.parse(envelope["result"].to_s)
      unless data.is_a?(Hash) && %w[completed needs_input no_changes].include?(data["outcome"])
        return failed("O agente devolveu um resultado fora do formato.")
      end

      Outcome.new(state: :finished, data:)
    rescue JSON::ParserError
      failed("O agente devolveu um resultado fora do formato.")
    end

    private

    def container_name(run_id) = "acervo-run-#{Integer(run_id)}"

    def failed(message) = Outcome.new(state: :failed, error: @log.scrub(message))

    def tail(*files)
      text = files.map { |file| File.exist?(file) ? File.read(file) : "" }.join("\n").strip
      @log.scrub(text[-500..] || text)
    end

    # Devolve nil quando o processo termina sozinho, ou o motivo da parada.
    def wait(pid, should_stop)
      started = now
      last_beat = now
      loop do
        return nil if Process.wait(pid, Process::WNOHANG)
        return :timeout if now - started > @time_limit
        return :interrupted if should_stop.call

        if now - last_beat >= @heartbeat_every
          last_beat = now
          return :canceled if yield
        end
        sleep @poll
      end
    end

    def kill(run_id)
      system("docker", "kill", container_name(run_id), out: File::NULL, err: File::NULL)
    end

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
