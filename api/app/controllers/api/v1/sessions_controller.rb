# Login (create), sessão atual (show) e logout (destroy).
# Contrato: specs/001-email-password-auth/contracts/session-api.md
module Api
  module V1
    class SessionsController < ApplicationController
      allow_unauthenticated_access only: :create

      rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
        render json: { error: "Muitas tentativas. Aguarde alguns minutos e tente novamente." },
          status: :too_many_requests
      }

      def create
        user = User.authenticate_by(
          email_address: params.require(:email_address),
          password: params.require(:password)
        )

        if user
          start_new_session_for(user)
          render json: { user: serialize(user) }, status: :created
        else
          render json: { error: "E-mail ou senha inválidos" }, status: :unauthorized
        end
      end

      def show
        render json: { user: serialize(Current.user) }
      end

      def destroy
        terminate_session
        head :no_content
      end

      private

      def serialize(user)
        user.slice(:id, :email_address)
      end
    end
  end
end
