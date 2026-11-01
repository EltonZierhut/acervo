require "test_helper"

class Initiatives::ExecutorTest < ActiveSupport::TestCase
  test "guarda só o digest" do
    token = Initiatives::Executor.rotate_token!
    executor = Initiatives::Executor.first
    assert_not_equal token, executor.token_digest
    assert_equal executor, Initiatives::Executor.authenticate(token)
  end

  test "trocar o token invalida o anterior" do
    old = Initiatives::Executor.rotate_token!
    new = Initiatives::Executor.rotate_token!
    assert_nil Initiatives::Executor.authenticate(old)
    assert Initiatives::Executor.authenticate(new)
    assert_equal 1, Initiatives::Executor.count
  end

  test "token vazio não autentica" do
    Initiatives::Executor.rotate_token!
    assert_nil Initiatives::Executor.authenticate("")
  end

  test "disponível se visto há menos de 2 min" do
    executor = Initiatives::Executor.new(last_seen_at: 1.minute.ago)
    assert executor.available?
    executor.last_seen_at = 3.minutes.ago
    assert_not executor.available?
    executor.last_seen_at = nil
    assert_not executor.available?
  end
end
