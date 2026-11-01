module AcervoExecutor
  # ~/.config/acervo-executor/config.yml. Contrato: specs/006-ai-task-automation/contracts/executor-cli.md
  class Config
    DEFAULT_IMAGE = "acervo-agent:latest".freeze
    REQUIRED = %w[api_url executor_token claude_oauth_token].freeze

    def self.default_path
      ENV["ACERVO_EXECUTOR_CONFIG"] || File.join(Dir.home, ".config/acervo-executor/config.yml")
    end

    def self.state_dir
      ENV["ACERVO_EXECUTOR_STATE"] || File.join(Dir.home, ".local/state/acervo-executor")
    end

    def self.load(path = default_path)
      raise Error, "Arquivo de configuração não encontrado: #{path}. Veja docs/executor.md." unless File.exist?(path)

      mode = File.stat(path).mode & 0o777
      if mode & 0o077 != 0
        raise Error, "#{path} guarda credenciais e está aberto a outros usuários. Rode: chmod 600 #{path}"
      end

      new(YAML.safe_load_file(path) || {})
    rescue Psych::Exception => e
      raise Error, "Não foi possível ler #{path}: #{e.message}"
    end

    def initialize(values)
      @values = values
      missing = REQUIRED.select { |key| values[key].to_s.empty? }
      raise Error, "Falta na configuração: #{missing.join(', ')}. Veja docs/executor.md." if missing.any?

      unless api_url.match?(%r{\Ahttps://}) || api_url.match?(%r{\Ahttp://(localhost|127\.0\.0\.1)(:\d+)?(/|\z)})
        raise Error, "api_url precisa usar https (http só para localhost)."
      end
    end

    def api_url = @values["api_url"].chomp("/")
    def executor_token = @values["executor_token"]
    def claude_oauth_token = @values["claude_oauth_token"]
    def max_budget_usd = @values["max_budget_usd"]
    def image_for(repository) = @values.dig("images", repository) || @values["image"] || DEFAULT_IMAGE
    def secrets = [ executor_token, claude_oauth_token ]
  end
end
