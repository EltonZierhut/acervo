module AcervoExecutor
  # Confere o acesso aos repositórios conectados, com o login do gh desta máquina (FR-005 e FR-006).
  class RepositoryChecker
    WRITE_PERMISSIONS = %w[WRITE MAINTAIN ADMIN].freeze
    NO_ACCESS = "Sem acesso a este repositório pelo computador do executor. Confira o nome e rode gh auth login " \
                "com uma conta que tenha acesso; em organizações, autorize também o acesso a ela.".freeze

    def initialize(client, log, shell: Shell.new)
      @client = client
      @log = log
      @shell = shell
    end

    def run
      @client.repository_checks.each do |repository|
        error = problem_with(repository)
        @client.report_repository({ repository:, valid: error.nil?, error: })
        @log.info("Repositório #{repository}: #{error || 'acesso confirmado'}")
      end
    end

    def problem_with(repository)
      result = @shell.run("gh", "repo", "view", repository, "--json", "viewerPermission,isArchived")
      return NO_ACCESS unless result.ok?

      info = JSON.parse(result.stdout)
      return "O repositório está arquivado." if info["isArchived"]
      return "A conta do executor não tem permissão de escrita neste repositório." unless WRITE_PERMISSIONS.include?(info["viewerPermission"])

      nil
    end
  end
end
