module AcervoExecutor
  # Guarda o resultado até o Acervo confirmar, para uma queda de rede não perder o PR já aberto.
  class Spool
    def initialize(client, log, dir: File.join(Config.state_dir, "pending"))
      @client = client
      @log = log
      @dir = dir
      FileUtils.mkdir_p(@dir, mode: 0o700)
    end

    # Devolve true se não sobrou nada para entregar.
    def deliver(run_id, result)
      File.write(path(run_id), JSON.generate(result), perm: 0o600)
      flush
    end

    def flush
      Dir[File.join(@dir, "*.json")].sort.each do |file|
        run_id = File.basename(file, ".json")
        begin
          @client.complete(run_id, JSON.parse(File.read(file)))
        rescue Client::Unavailable
          return false
        rescue Client::Rejected => e
          # Recusa definitiva (tarefa apagada, por exemplo): tentar de novo não adianta.
          raise if e.status == 401

          @log.info("Resultado da execução #{run_id} recusado: #{e.message}")
        end
        FileUtils.rm_f(file)
      end
      true
    end

    private

    def path(run_id) = File.join(@dir, "#{Integer(run_id)}.json")
  end
end
