require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module Acervo
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    config.time_zone = "America/Sao_Paulo"
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [:"pt-BR", :en]

    # A coluna "searchable" (tsvector gerada) e a função auxiliar não
    # cabem no schema.rb, por isso o schema é salvo em SQL.
    config.active_record.schema_format = :sql
  end
end
