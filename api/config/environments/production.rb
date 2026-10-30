require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # HTTPS: o Cloud Run termina o TLS e repassa a requisição por HTTP ao container.
  # assume_ssl faz o Rails tratar tudo como HTTPS; o redirecionamento HTTP → HTTPS
  # é feito pela própria plataforma. force_ssl envia HSTS e marca cookies como seguros.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Interface (build do React em public/). Arquivos de assets/ têm hash no nome,
  # então podem ficar em cache por um ano; o index.html é servido sem cache pelo SpaController.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}, immutable" }

  # Usado pelo rate_limit do login. Em memória vale para um único processo;
  # por isso o deploy limita o serviço a uma instância (bin/deploy-gcp).
  config.cache_store = :memory_store
end
