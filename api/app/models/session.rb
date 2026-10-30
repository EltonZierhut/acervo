# Um acesso ativo de um usuário a partir de um dispositivo.
# Identificada por um token aleatório guardado num cookie assinado.
class Session < ApplicationRecord
  IDLE_TIMEOUT = 30.days
  ACTIVITY_INTERVAL = 1.hour

  belongs_to :user
  has_secure_token :token

  before_validation -> { self.last_active_at ||= Time.current }, on: :create

  def expired?
    last_active_at < IDLE_TIMEOUT.ago
  end

  # Registra uso, no máximo uma vez por ACTIVITY_INTERVAL para evitar escrita a cada requisição.
  # Retorna true quando atualizou (o cookie deve ser renovado).
  def touch_activity!
    return false if last_active_at > ACTIVITY_INTERVAL.ago

    update!(last_active_at: Time.current)
    true
  end
end
