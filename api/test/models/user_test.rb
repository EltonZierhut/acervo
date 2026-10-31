require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normaliza o e-mail" do
    user = User.new(email_address: "  Voce@Exemplo.COM ", password: "senha-bem-longa")
    assert_equal "voce@exemplo.com", user.email_address
  end

  test "e-mail é único sem diferenciar maiúsculas" do
    user = User.new(email_address: "DONO@acervo.test", password: "senha-bem-longa")
    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :taken)
  end

  test "e-mail precisa ter formato válido" do
    assert_not User.new(email_address: "sem-arroba", password: "senha-bem-longa").valid?
  end

  test "senha precisa de pelo menos 12 caracteres" do
    user = User.new(email_address: "novo@acervo.test", password: "curta")
    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "autentica pelo e-mail normalizado" do
    assert_equal users(:owner),
      User.authenticate_by(email_address: " DONO@acervo.test", password: SignInHelper::TEST_PASSWORD)
  end

  test "reset_password! troca a senha e encerra as sessões" do
    user = users(:owner)
    2.times { user.sessions.create! }

    closed = user.reset_password!("outra-senha-longa", "outra-senha-longa")

    assert_equal 2, closed
    assert_equal 0, user.sessions.count
    assert user.reload.authenticate("outra-senha-longa")
    assert_not user.authenticate(SignInHelper::TEST_PASSWORD)
  end

  test "reset_password! recusa confirmação diferente e mantém as sessões" do
    user = users(:owner)
    user.sessions.create!

    assert_raises(ActiveRecord::RecordInvalid) { user.reset_password!("outra-senha-longa", "diferente-da-outra") }
    assert_equal 1, user.sessions.count
  end
end
