# Em produção, falha logo na inicialização se faltar alguma credencial,
# em vez de quebrar depois, na primeira requisição.
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  missing = %w[DATABASE_URL SECRET_KEY_BASE].select { |name| ENV[name].blank? }

  if missing.any?
    abort "Variáveis de ambiente obrigatórias ausentes em produção: #{missing.join(', ')}. " \
          "Veja docs/deploy-gcp.md."
  end
end
