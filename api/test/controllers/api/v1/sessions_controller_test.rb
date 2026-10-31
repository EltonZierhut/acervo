require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:owner) }

  def login(email: @user.email_address, password: SignInHelper::TEST_PASSWORD)
    post api_v1_session_path, params: { email_address: email, password: }, as: :json
  end

  # --- História 1: entrar ---

  test "login válido cria sessão e cookie seguro" do
    assert_difference -> { Session.count }, 1 do
      login
    end

    assert_response :created
    assert_equal({ "id" => @user.id, "email_address" => @user.email_address }, json["user"])

    set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
    assert_match(/session_token=/, set_cookie)
    assert_match(/httponly/i, set_cookie)
    assert_match(/samesite=lax/i, set_cookie)
    assert_not json.to_s.include?(Session.last.token), "o token não deve aparecer no corpo"
  end

  test "aceita e-mail com maiúsculas e espaços" do
    login(email: "  DONO@Acervo.test ")
    assert_response :created
  end

  test "senha errada e e-mail inexistente têm a mesma resposta" do
    login(password: "senha-errada-123")
    assert_response :unauthorized
    wrong_password = json

    login(email: "ninguem@acervo.test")
    assert_response :unauthorized
    assert_equal wrong_password, json
    assert_equal "E-mail ou senha inválidos", json["error"]
  end

  test "campos ausentes retornam 400" do
    post api_v1_session_path, params: { email_address: @user.email_address }, as: :json
    assert_response :bad_request
  end

  test "login sem JSON é recusado com 415" do
    post api_v1_session_path, params: { email_address: @user.email_address, password: SignInHelper::TEST_PASSWORD }
    assert_response :unsupported_media_type
  end

  test "sessão atual: 200 logado e 401 sem login" do
    get api_v1_session_path
    assert_response :unauthorized
    assert_equal "Não autenticado", json["error"]

    sign_in_as @user
    get api_v1_session_path
    assert_response :ok
    assert_equal @user.email_address, json.dig("user", "email_address")
  end

  test "sessão sem uso há mais de 30 dias expira e é apagada" do
    sign_in_as @user
    Session.last.update!(last_active_at: 31.days.ago)

    assert_difference -> { Session.count }, -1 do
      get api_v1_session_path
    end
    assert_response :unauthorized
  end

  test "atividade renova a sessão no máximo uma vez por hora" do
    sign_in_as @user
    session = Session.last
    session.update!(last_active_at: 2.hours.ago)

    get api_v1_session_path
    assert_response :ok
    assert_in_delta Time.current, session.reload.last_active_at, 5.seconds
  end

  # --- História 2: sair ---

  test "logout apaga a sessão e o cookie antigo deixa de funcionar" do
    sign_in_as @user
    old_cookie = cookies[:session_token]

    assert_difference -> { Session.count }, -1 do
      delete api_v1_session_path, as: :json
    end
    assert_response :no_content

    cookies[:session_token] = old_cookie
    get api_v1_codes_snippets_path
    assert_response :unauthorized
  end

  test "logout sem login retorna 401" do
    delete api_v1_session_path, as: :json
    assert_response :unauthorized
  end

  test "sair de um dispositivo mantém o outro logado" do
    other_device = open_session
    other_device.post api_v1_session_path,
      params: { email_address: @user.email_address, password: SignInHelper::TEST_PASSWORD }, as: :json
    assert_equal 201, other_device.response.status

    sign_in_as @user
    delete api_v1_session_path, as: :json
    assert_response :no_content

    other_device.get api_v1_session_path
    assert_equal 200, other_device.response.status
  end

  # --- História 3: limite de tentativas ---

  test "a 11ª tentativa em 3 minutos é recusada, mesmo com a senha certa" do
    10.times do
      login(password: "senha-errada-123")
      assert_response :unauthorized
    end

    login
    assert_response :too_many_requests
    assert_equal "Muitas tentativas. Aguarde alguns minutos e tente novamente.", json["error"]

    travel 3.minutes + 1.second do
      login
      assert_response :created
    end
  end
end
