module AcervoExecutor
  # Pasta temporária da execução: clone do repositório e anexos, fora do clone.
  class Workspace
    PR_TEMPLATES = %w[.github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md
                      docs/pull_request_template.md pull_request_template.md PULL_REQUEST_TEMPLATE.md].freeze
    MAX_TEMPLATE_BYTES = 20_000

    attr_reader :root, :repo_dir, :attachments_dir, :default_branch

    def initialize(shell: Shell.new)
      @shell = shell
    end

    def self.open(**options)
      workspace = new(**options)
      Dir.mktmpdir("acervo-run-") do |root|
        workspace.prepare_dirs(root)
        yield workspace
      end
    end

    def prepare_dirs(root)
      @root = root
      @repo_dir = File.join(root, "repo")
      @attachments_dir = File.join(root, "attachments")
      FileUtils.mkdir_p(@attachments_dir)
    end

    def clone(repository)
      view = @shell.run("gh", "repo", "view", repository, "--json", "defaultBranchRef,isEmpty")
      raise Error, "Sem acesso ao repositório #{repository}. Confira o gh auth login." unless view.ok?

      info = JSON.parse(view.stdout)
      @default_branch = info.dig("defaultBranchRef", "name")
      raise Error, "O repositório #{repository} está vazio." if info["isEmpty"] || @default_branch.to_s.empty?

      result = @shell.run("gh", "repo", "clone", repository, @repo_dir, "--", "--no-tags")
      raise Error, "Não foi possível clonar #{repository}." unless result.ok?
    end

    # Grava com nome próprio, sem usar o nome enviado. Devolve os caminhos vistos dentro do container.
    def save_images(images, client)
      images.map.with_index(1) do |image, index|
        extension = { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp", "image/gif" => "gif" }
          .fetch(image["content_type"], "img")
        name = "imagem-#{index}.#{extension}"
        File.binwrite(File.join(@attachments_dir, name), client.download_image(image["id"]))
        "/attachments/#{name}"
      end
    end

    def pr_template
      path = PR_TEMPLATES.map { |name| File.join(@repo_dir, name) }.find do |file|
        File.file?(file) && !File.symlink?(file)
      end
      path && File.read(path, MAX_TEMPLATE_BYTES)
    end
  end
end
