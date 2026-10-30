require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.force_ssl = ENV["FORCE_SSL"] == "true"
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # Usado pelo rate_limit do login. Em memória vale para um único processo;
  # com vários workers/servidores, trocar por um cache compartilhado.
  config.cache_store = :memory_store
end
