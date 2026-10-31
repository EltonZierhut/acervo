# Sessão e usuário da requisição atual, definidos pelo concern Authentication.
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
