require_relative "test_helper"

class PublisherTest < Minitest::Test
  include TestSupport

  # git de verdade; gh simulado.
  class FakeShell < AcervoExecutor::Shell
    attr_reader :gh_calls
    attr_accessor :existing_pr

    def initialize
      super
      @gh_calls = []
    end

    def run(*argv, **options)
      return super unless argv.first == "gh"

      @gh_calls << argv
      return Result.new(JSON.generate(existing_pr ? [ { url: existing_pr } ] : []), "", true) if argv[2] == "list"

      Result.new("https://github.com/a/b/pull/9\n", "", true)
    end
  end

  Workspace = Struct.new(:root, :repo_dir, :default_branch)

  RUN = { "id" => 7, "repository" => "a/b", "task" => { "id" => 3, "title" => "Tarefa", "initiative_id" => 2 } }.freeze

  def publish(repo, root, data = { "pr_title" => "Título", "summary" => "Resumo" }, shell: FakeShell.new)
    publisher = AcervoExecutor::Publisher.new(shell:, api_url: "https://acervo.test")
    publisher.publish(run: RUN, workspace: Workspace.new(root, repo, "main"), data:)
  end

  def test_faz_commit_push_e_abre_pr_na_branch_padrao
    with_repo do |repo, bare, root|
      File.write(File.join(repo, "b.txt"), "b\n")
      shell = FakeShell.new
      result = publish(repo, root, shell:)

      assert_equal "acervo/task-3-run-7", result[:branch]
      assert_equal "https://github.com/a/b/pull/9", result[:pull_request_url]
      assert_includes git(bare, "branch", "--list"), "acervo/task-3-run-7"
      assert_equal "b.txt", git(bare, "show", "--name-only", "--format=", "acervo/task-3-run-7").strip
      refute_includes git(bare, "log", "main", "--format=%s"), "Título"

      create = shell.gh_calls.find { |call| call[2] == "create" }
      assert_equal "a/b", create[create.index("--repo") + 1]
      assert_equal "main", create[create.index("--base") + 1]
      assert_equal "Título", create[create.index("--title") + 1]
    end
  end

  def test_sem_alteracoes_nao_publica
    with_repo do |repo, bare, root|
      shell = FakeShell.new
      assert_nil publish(repo, root, shell:)
      assert_empty shell.gh_calls
      refute_includes git(bare, "branch", "--list"), "acervo/"
    end
  end

  def test_recusa_alteracao_em_workflows_sem_publicar
    with_repo do |repo, bare, root|
      FileUtils.mkdir_p(File.join(repo, ".github/workflows"))
      File.write(File.join(repo, ".github/workflows/x.yml"), "on: push\n")
      File.write(File.join(repo, "c.txt"), "c\n")
      shell = FakeShell.new
      assert_raises(AcervoExecutor::Publisher::WorkflowChange) { publish(repo, root, shell:) }
      assert_empty shell.gh_calls
      refute_includes git(bare, "branch", "--list"), "acervo/"
    end
  end

  def test_recusa_workflows_trocado_por_link_simbolico
    with_repo do |repo, _bare, root|
      FileUtils.mkdir_p(File.join(repo, ".github"))
      File.symlink("../outro", File.join(repo, ".github/workflows"))
      assert_raises(AcervoExecutor::Publisher::WorkflowChange) { publish(repo, root) }
    end
  end

  def test_nao_executa_hooks_do_repositorio
    with_repo do |repo, _bare, root|
      marker = File.join(root, "rodou")
      %w[pre-commit pre-push commit-msg].each do |hook|
        path = File.join(repo, ".git/hooks", hook)
        File.write(path, "#!/bin/sh\ntouch #{marker}\n")
        File.chmod(0o755, path)
      end
      File.write(File.join(repo, "b.txt"), "b\n")
      publish(repo, root)
      refute File.exist?(marker), "um hook do repositório rodou com as credenciais da máquina"
    end
  end

  def test_reaproveita_pr_ja_aberto
    with_repo do |repo, _bare, root|
      File.write(File.join(repo, "b.txt"), "b\n")
      shell = FakeShell.new
      shell.existing_pr = "https://github.com/a/b/pull/5"
      assert_equal "https://github.com/a/b/pull/5", publish(repo, root, shell:)[:pull_request_url]
      assert_empty(shell.gh_calls.select { |call| call[2] == "create" })
    end
  end

  def test_corpo_traz_decisoes_perguntas_testes_e_links_nao_lidos
    run = RUN.merge("questions" => [ { "body" => "Qual?", "answer" => "Esta" } ])
    body = AcervoExecutor::Publisher.new(api_url: "https://acervo.test").body_for(
      run, { "pr_body" => "Corpo", "decisions" => [ "Usei X" ], "tests" => "Passaram", "unread_links" => [ "https://x" ] }
    )
    assert_includes body, "Corpo"
    assert_includes body, "- Usei X"
    assert_includes body, "- Qual? → Esta"
    assert_includes body, "Passaram"
    assert_includes body, "- https://x"
    assert_includes body, "https://acervo.test/iniciativas/2"
  end
end
