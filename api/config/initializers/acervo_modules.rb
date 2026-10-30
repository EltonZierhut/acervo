# Registro dos módulos do Acervo.
# Para adicionar um módulo novo: inclua-o em config/modules.yml,
# crie o namespace em app/models/<modulo>/ e app/controllers/api/v1/<modulo>/
# e adicione as rotas dele em config/routes.rb.
Rails.application.config.x.acervo_modules =
  Rails.application.config_for(:modules).fetch(:modules, [])
