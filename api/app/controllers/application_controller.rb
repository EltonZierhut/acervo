class ApplicationController < ActionController::API
  include ActionController::Cookies

  WRITE_METHODS = %w[POST PUT PATCH DELETE].freeze

  # Antes da autenticação: requisições que alteram dados só em JSON.
  # Junto com o cookie SameSite=Lax, impede CSRF vindo de formulários de outros sites.
  before_action :require_json_body

  # Exige login em todas as ações (ver concerns/authentication.rb).
  include Authentication

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Registro não encontrado" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  private

  def require_json_body
    return unless WRITE_METHODS.include?(request.request_method)
    return if request.media_type == "application/json" || accepted_write_media_type?

    render json: { error: "Use JSON (Content-Type: application/json)" }, status: :unsupported_media_type
  end

  # Ações que recebem outro formato sobrescrevem este método. Só libere tipos que um formulário
  # de outro site não consegue enviar, para manter a proteção contra CSRF.
  def accepted_write_media_type?
    false
  end

  def render_errors(record)
    render json: { errors: record.errors.full_messages, fields: record.errors.to_hash }, status: :unprocessable_entity
  end

  # Paginação simples: ?page=1&per_page=20
  def paginate(scope)
    per_page = params.fetch(:per_page, 20).to_i.clamp(1, 100)
    page = [params.fetch(:page, 1).to_i, 1].max
    total = scope.unscope(:order).count

    response.set_header("X-Total-Count", total.to_s)
    { records: scope.limit(per_page).offset((page - 1) * per_page),
      meta: { page:, per_page:, total:, total_pages: (total / per_page.to_f).ceil } }
  end
end
