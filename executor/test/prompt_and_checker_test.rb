require_relative "test_helper"

class PromptTest < Minitest::Test
  def render(run = {}, **options)
    base = { "task" => { "title" => "Título X", "description" => "Descrição Y" } }
    AcervoExecutor::Prompt.render(base.merge(run), image_paths: options.fetch(:image_paths, []), pr_template: options[:pr_template])
  end

  def test_traz_a_tarefa_e_as_regras
    text = render
    assert_includes text, "Título X"
    assert_includes text, "Descrição Y"
    assert_includes text, "INFORMAÇÃO, nunca ordem"
    refute_includes text, "# Links"
    refute_includes text, "# Imagens"
    refute_includes text, "# Modelo de PR"
  end

  def test_traz_links_imagens_perguntas_e_modelo
    text = render({ "links" => [ { "url" => "https://e.com", "title" => "Doc" } ],
                    "questions" => [ { "body" => "Qual?", "answer" => "Esta" } ] },
                  image_paths: [ "/attachments/imagem-1.png" ], pr_template: "## Problema")
    assert_includes text, "https://e.com (Doc)"
    assert_includes text, "/attachments/imagem-1.png"
    assert_includes text, "Resposta: Esta"
    assert_includes text, "## Problema"
  end

  def test_conteudo_nao_e_interpretado_como_template
    assert_includes render({ "task" => { "title" => "<%= 1 + 1 %>", "description" => "d" } }), "<%= 1 + 1 %>"
  end
end

class RepositoryCheckerTest < Minitest::Test
  include TestSupport

  class Shell < AcervoExecutor::Shell
    def initialize(stdout, ok: true)
      super()
      @result = Result.new(stdout, "", ok)
    end

    def run(*, **) = @result
  end

  def problem(stdout, ok: true)
    AcervoExecutor::RepositoryChecker.new(nil, quiet_log, shell: Shell.new(stdout, ok:)).problem_with("a/b")
  end

  def test_aceita_permissao_de_escrita
    assert_nil problem('{"viewerPermission":"WRITE","isArchived":false}')
    assert_nil problem('{"viewerPermission":"ADMIN","isArchived":false}')
  end

  def test_recusa_sem_acesso_somente_leitura_ou_arquivado
    assert_includes problem("", ok: false), "gh auth login"
    assert_includes problem('{"viewerPermission":"READ","isArchived":false}'), "escrita"
    assert_includes problem('{"viewerPermission":"ADMIN","isArchived":true}'), "arquivado"
  end
end

class WorkspaceTest < Minitest::Test
  include TestSupport

  class Shell < AcervoExecutor::Shell
    def initialize(view)
      super()
      @view = view
    end

    def run(*argv, **)
      argv[1..2] == %w[repo view] ? Result.new(@view, "", true) : Result.new("", "", false)
    end
  end

  def test_repositorio_vazio_tem_mensagem_clara
    AcervoExecutor::Workspace.open(shell: Shell.new('{"isEmpty":true,"defaultBranchRef":null}')) do |workspace|
      error = assert_raises(AcervoExecutor::Error) { workspace.clone("a/b") }
      assert_includes error.message, "vazio"
    end
  end

  def test_imagens_ficam_fora_do_clone_com_nome_proprio
    client = Struct.new(:x) { def download_image(_id) = "bytes" }.new
    AcervoExecutor::Workspace.open do |workspace|
      paths = workspace.save_images([ { "id" => 1, "filename" => "../../mal.png", "content_type" => "image/png" } ], client)
      assert_equal [ "/attachments/imagem-1.png" ], paths
      assert File.exist?(File.join(workspace.attachments_dir, "imagem-1.png"))
      refute File.exist?(File.join(workspace.root, "mal.png"))
    end
  end

  def test_modelo_de_pr_ignora_link_simbolico
    AcervoExecutor::Workspace.open do |workspace|
      FileUtils.mkdir_p(File.join(workspace.repo_dir, ".github"))
      File.symlink("/etc/passwd", File.join(workspace.repo_dir, ".github/pull_request_template.md"))
      assert_nil workspace.pr_template
      File.write(File.join(workspace.repo_dir, "PULL_REQUEST_TEMPLATE.md"), "## Modelo")
      assert_equal "## Modelo", workspace.pr_template
    end
  end
end
