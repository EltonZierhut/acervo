module AcervoExecutor
  module CLI
    USAGE = "Uso: acervo-executor run | check | version".freeze

    def self.start(argv)
      case argv.first
      when "run" then run
      when "check" then check
      when "version" then puts VERSION
      else
        warn USAGE
        return 1
      end
      0
    rescue Error => e
      warn e.message
      1
    end

    def self.run
      config = Config.load
      log = Log.new(secrets: config.secrets)
      client = Client.new(config)
      loop = Loop.new(
        config:, client:, log:,
        agent: Agent.new(config, log),
        publisher: Publisher.new(api_url: config.api_url),
        spool: Spool.new(client, log),
        checker: RepositoryChecker.new(client, log)
      )
      %w[INT TERM].each { |signal| trap(signal) { loop.stop! } }
      loop.run_forever
    end

    def self.check
      config = Config.load
      shell = Shell.new
      failures = 0
      report = lambda do |label, ok, hint = nil|
        puts "#{ok ? 'ok   ' : 'ERRO '} #{label}#{" - #{hint}" if !ok && hint}"
        failures += 1 unless ok
      end

      report.call("Configuração", true)
      report.call("git", shell.run("git", "--version").ok?)
      report.call("gh com login", shell.run("gh", "auth", "status").ok?, "rode gh auth login")
      report.call("Git com nome e e-mail", shell.run("git", "config", "user.email").ok?, "rode git config --global user.email ...")
      report.call("Docker", shell.run("docker", "info").ok?, "inicie o Docker")
      image = config.image_for(nil)
      report.call("Imagem #{image}", shell.run("docker", "image", "inspect", image).ok?, "rode docker build -t #{image} executor/")
      begin
        Client.new(config).repository_checks
        report.call("API do Acervo", true)
      rescue Error => e
        report.call("API do Acervo", false, e.message)
      end
      raise Error, "#{failures} verificação(ões) falharam." if failures.positive?

      puts "Tudo certo."
    end
  end
end
