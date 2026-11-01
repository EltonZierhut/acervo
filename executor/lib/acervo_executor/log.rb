module AcervoExecutor
  # Mensagens no terminal e, durante uma execução, no arquivo dela. Credenciais nunca são gravadas.
  class Log
    def initialize(secrets: [], io: $stdout)
      @secrets = secrets.compact.reject(&:empty?)
      @io = io
      @file = nil
    end

    def info(message)
      line = "[#{Time.now.strftime('%F %T')}] #{scrub(message)}"
      @io.puts(line)
      @file&.puts(line)
    end

    def scrub(text)
      @secrets.reduce(text.to_s) { |result, secret| result.gsub(secret, "[oculto]") }
        .gsub(/gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-ant-[A-Za-z0-9_-]{20,}/, "[oculto]")
    end

    def to_file(path)
      FileUtils.mkdir_p(File.dirname(path), mode: 0o700)
      File.open(path, "a", 0o600) do |file|
        file.sync = true
        @file = file
        yield
      end
    ensure
      @file = nil
    end
  end
end
