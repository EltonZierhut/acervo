require "test_helper"

# SC-001: toda rota de dados da API exige login. Percorre as rotas registradas,
# então cobre automaticamente os módulos que forem adicionados no futuro.
class AuthenticationRequiredTest < ActionDispatch::IntegrationTest
  PUBLIC_ROUTES = [ %w[POST /api/v1/session] ].freeze

  def api_routes
    Rails.application.routes.routes.filter_map do |route|
      verb = route.verb.to_s
      path = route.path.spec.to_s.sub("(.:format)", "")
      next if verb.blank? || !path.start_with?("/api/v1")
      next if PUBLIC_ROUTES.include?([ verb, path ])

      [ verb, path.gsub(/:\w+/, "1") ]
    end.uniq
  end

  test "existem rotas de dados para verificar" do
    assert_operator api_routes.size, :>=, 5
  end

  test "todas as rotas /api/v1 respondem 401 sem login" do
    api_routes.each do |verb, path|
      if verb == "GET"
        get path
      else
        # JSON para passar pela checagem de Content-Type e chegar na autenticação.
        send(verb.downcase, path, params: {}, as: :json)
      end

      assert_equal 401, response.status, "#{verb} #{path} deveria exigir login"
      assert_equal({ "error" => "Não autenticado" }, response.parsed_body, "#{verb} #{path} não pode expor dados")
    end
  end

  test "health check continua público" do
    get rails_health_check_path
    assert_response :ok
  end
end
