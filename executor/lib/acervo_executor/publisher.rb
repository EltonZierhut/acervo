module AcervoExecutor
  # Publica o que o agente deixou nos arquivos. Roda fora do container, com as credenciais da máquina,
  # e por isso não executa nada que venha do repositório: hooks ficam desligados.
  class Publisher
    class WorkflowChange < Error; end

    FORBIDDEN = %r{\A\.github/workflows(/|\z)}i
    MAX_TITLE = 200

    def initialize(shell: Shell.new, api_url: nil)
      @shell = shell
      @api_url = api_url
    end

    # Devolve os arquivos alterados, já preparados para o commit.
    def staged_changes(repo_dir)
      git!(repo_dir, "add", "-A")
      git!(repo_dir, "diff", "--cached", "--name-only", "-z").stdout.split("\0")
    end

    # Devolve { branch:, pull_request_url: }, ou nil se não houver alterações.
    def publish(run:, workspace:, data:)
      repo_dir = workspace.repo_dir
      changes = staged_changes(repo_dir)
      return nil if changes.empty?

      blocked = changes.grep(FORBIDDEN)
      if blocked.any?
        raise WorkflowChange, "A tarefa alterou workflows do repositório (#{blocked.first(3).join(', ')}). Por segurança, " \
                              "nada foi publicado. Faça essa mudança à mão."
      end

      branch = "acervo/task-#{Integer(run.dig('task', 'id'))}-run-#{Integer(run['id'])}"
      title = title_for(run, data)
      git!(repo_dir, "checkout", "-q", "-b", branch)
      git!(repo_dir, "commit", "-q", "--no-verify", "-m", title)
      git!(repo_dir, "push", "--no-verify", "-q", "origin", "HEAD:refs/heads/#{branch}")

      { branch:, pull_request_url: find_or_create_pr(run, workspace, branch, title, data) }
    end

    def body_for(run, data)
      sections = [ data["pr_body"].to_s.strip.empty? ? data["summary"].to_s.strip : data["pr_body"].to_s.strip ]
      sections << list("Decisões tomadas", data["decisions"])
      answered = Array(run["questions"]).map { |q| "#{q['body']} → #{q['answer']}" }
      sections << list("Perguntas respondidas", answered)
      sections << "## Testes\n\n#{data['tests']}" unless data["tests"].to_s.strip.empty?
      sections << list("Links não lidos", data["unread_links"])
      sections << footer(run)
      sections.compact.join("\n\n")
    end

    private

    def title_for(run, data)
      title = data["pr_title"].to_s.lines.first.to_s.strip
      title = run.dig("task", "title").to_s.lines.first.to_s.strip if title.empty?
      title[0, MAX_TITLE]
    end

    def list(heading, items)
      items = Array(items).map { |item| item.to_s.strip }.reject(&:empty?)
      return nil if items.empty?

      "## #{heading}\n\n#{items.map { |item| "- #{item}" }.join("\n")}"
    end

    def footer(run)
      initiative = run.dig("task", "initiative_id")
      place = @api_url && initiative ? "[tarefa no Acervo](#{@api_url}/iniciativas/#{Integer(initiative)})" : "Acervo"
      "---\nGerado pelo executor do Acervo: #{place}, tarefa ##{run.dig('task', 'id')}, execução ##{run['id']}. Aguardando revisão humana."
    end

    def find_or_create_pr(run, workspace, branch, title, data)
      repository = run["repository"]
      existing = gh!("pr", "list", "--repo", repository, "--head", branch, "--state", "open", "--json", "url")
      url = JSON.parse(existing.stdout).first&.fetch("url")
      return url if url

      body_file = File.join(workspace.root, "pr-body.md")
      File.write(body_file, body_for(run, data))
      created = gh!("pr", "create", "--repo", repository, "--base", workspace.default_branch, "--head", branch,
                    "--title", title, "--body-file", body_file)
      created.stdout.lines.map(&:strip).grep(%r{\Ahttps://github\.com/}).last ||
        raise(Error, "O gh não devolveu o endereço do PR.")
    end

    def git!(repo_dir, *args)
      result = @shell.run("git", "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false", "-C", repo_dir, *args)
      raise Error, "Falha no git #{args.first}: #{result.stderr.to_s[0, 500]}" unless result.ok?

      result
    end

    def gh!(*args)
      result = @shell.run("gh", *args)
      raise Error, "Falha no gh #{args.first(2).join(' ')}: #{result.stderr.to_s[0, 500]}" unless result.ok?

      result
    end
  end
end
