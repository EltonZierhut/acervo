module AcervoExecutor
  # API do executor. Contrato: specs/006-ai-task-automation/contracts/executor-api.md
  class Client
    class Unavailable < Error; end

    class Rejected < Error
      attr_reader :status

      def initialize(status, message)
        @status = status
        super(message)
      end
    end

    PREFIX = "/api/v1/initiatives/executor".freeze
    # O serviço pode estar desligado e levar alguns segundos para subir.
    TIMEOUT = 60

    def initialize(config)
      @config = config
    end

    def claim
      response = request(Net::HTTP::Post, "/claim", { version: VERSION })
      response.code == "204" ? nil : JSON.parse(response.body).fetch("run")
    end

    def heartbeat(run_id)
      JSON.parse(request(Net::HTTP::Post, "/runs/#{run_id}/heartbeat", {}).body).fetch("cancel")
    rescue Rejected => e
      raise unless e.status == 404

      true # Tarefa apagada: para do mesmo modo.
    end

    def ask(run_id, questions) = request(Net::HTTP::Post, "/runs/#{run_id}/questions", { questions: })
    def complete(run_id, result) = request(Net::HTTP::Post, "/runs/#{run_id}/complete", result)
    def repository_checks = JSON.parse(request(Net::HTTP::Get, "/repository_checks").body).fetch("repositories")
    def report_repository(body) = request(Net::HTTP::Post, "/repository_checks", body)
    def download_image(id) = request(Net::HTTP::Get, "/images/#{id}").body

    private

    def request(klass, path, body = nil)
      uri = URI("#{@config.api_url}#{PREFIX}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      req = klass.new(uri)
      req["Authorization"] = "Bearer #{@config.executor_token}"
      req["Accept"] = "application/json"
      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      check(http.request(req))
    rescue SocketError, SystemCallError, IOError, Timeout::Error, OpenSSL::SSL::SSLError => e
      raise Unavailable, "Sem conexão com o Acervo: #{e.class}"
    end

    def check(response)
      code = response.code.to_i
      return response if code < 300
      raise Unavailable, "O Acervo respondeu #{code}" if code >= 500 || code == 429
      raise Rejected.new(code, "Token do executor inválido. Gere outro com acervo:executor:create.") if code == 401

      raise Rejected.new(code, "O Acervo recusou o pedido (#{code}): #{response.body.to_s[0, 300]}")
    end
  end
end
