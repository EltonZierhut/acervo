require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup { @user = users(:owner) }

  test "gera token e registra a atividade ao criar" do
    session = @user.sessions.create!
    assert session.token.present?
    assert_in_delta Time.current, session.last_active_at, 1.second
  end

  test "expira após 30 dias sem uso" do
    session = @user.sessions.create!(last_active_at: 29.days.ago)
    assert_not session.expired?

    session.update!(last_active_at: 31.days.ago)
    assert session.expired?
  end

  test "touch_activity! atualiza no máximo uma vez por hora" do
    session = @user.sessions.create!(last_active_at: 10.minutes.ago)
    assert_not session.touch_activity!

    session.update!(last_active_at: 2.hours.ago)
    assert session.touch_activity!
    assert_in_delta Time.current, session.last_active_at, 1.second
  end
end
