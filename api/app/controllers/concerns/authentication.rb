# Autenticação por sessão guardada no banco e identificada por cookie assinado.
#
# Toda rota exige login por padrão. Para liberar uma ação:
#   allow_unauthenticated_access only: :create
module Authentication
  extend ActiveSupport::Concern

  COOKIE_NAME = :session_token

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_active_session
  end

  def find_active_session
    token = cookies.signed[COOKIE_NAME]
    return if token.blank?

    session = Session.find_by(token:)
    return unless session

    if session.expired?
      session.destroy
      cookies.delete(COOKIE_NAME)
      return
    end

    write_session_cookie(session) if session.touch_activity!
    session
  end

  def request_authentication
    render json: { error: "Não autenticado" }, status: :unauthorized
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      write_session_cookie(session)
    end
  end

  def terminate_session
    Current.session&.destroy
    Current.session = nil
    cookies.delete(COOKIE_NAME)
  end

  def write_session_cookie(session)
    cookies.signed[COOKIE_NAME] = {
      value: session.token,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      expires: Session::IDLE_TIMEOUT.from_now
    }
  end
end
