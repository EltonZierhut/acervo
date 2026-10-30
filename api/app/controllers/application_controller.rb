class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Registro não encontrado" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  private

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
