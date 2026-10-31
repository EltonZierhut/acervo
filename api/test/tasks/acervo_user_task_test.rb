require "test_helper"
require "rake"

class AcervoUserTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("acervo:user:create")
  end

  # Executa a tarefa com as linhas como entrada. Retorna [saída, erros, código de saída].
  def run_task(name, *lines)
    task = Rake::Task["acervo:user:#{name}"]
    task.reenable
    status = 0
    original_stdin = $stdin
    $stdin = StringIO.new(lines.map { |line| "#{line}\n" }.join)

    out, err = capture_io do
      task.invoke
    rescue SystemExit => e
      status = e.status
    end
    [ out, err, status ]
  ensure
    $stdin = original_stdin
  end

  test "cria a conta quando não existe nenhuma" do
    User.delete_all

    out, _err, status = run_task(:create, "Voce@Exemplo.com", "senha-bem-longa", "senha-bem-longa")

    assert_equal 0, status
    assert_match "Usuário voce@exemplo.com criado", out
    assert User.find_by(email_address: "voce@exemplo.com").authenticate("senha-bem-longa")
  end

  test "recusa criar uma segunda conta" do
    assert_no_difference -> { User.count } do
      _out, err, status = run_task(:create, "outro@acervo.test", "senha-bem-longa", "senha-bem-longa")
      assert_equal 1, status
      assert_match "Nesta versão o Acervo tem um único usuário", err
    end
  end

  test "recusa senha curta e confirmação diferente" do
    User.delete_all

    _out, err, status = run_task(:create, "voce@exemplo.com", "curta", "curta")
    assert_equal 1, status
    assert_match "Senha é muito curta", err

    _out, err, status = run_task(:create, "voce@exemplo.com", "senha-bem-longa", "outra-senha-longa")
    assert_equal 1, status
    assert_match "Confirmação da senha não confere", err
    assert_equal 0, User.count
  end

  test "redefine a senha e encerra as sessões" do
    user = users(:owner)
    2.times { user.sessions.create! }

    out, _err, status = run_task(:reset_password, " DONO@acervo.test", "nova-senha-longa", "nova-senha-longa")

    assert_equal 0, status
    assert_match "Senha redefinida. 2 sessão(ões) encerrada(s).", out
    assert user.reload.authenticate("nova-senha-longa")
    assert_equal 0, user.sessions.count
  end

  test "redefinição para e-mail inexistente" do
    _out, err, status = run_task(:reset_password, "ninguem@acervo.test")
    assert_equal 1, status
    assert_match "Nenhum usuário com o e-mail ninguem@acervo.test.", err
  end
end
