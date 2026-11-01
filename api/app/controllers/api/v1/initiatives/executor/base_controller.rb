module Api
  module V1
    module Initiatives
      module Executor
        # Rotas do programa executor. Sessão de navegador não vale aqui; só o token (spec 006, FR-023).
        class BaseController < ApplicationController
          allow_unauthenticated_access
          before_action :authenticate_executor

          rescue_from ArgumentError do |e|
            render json: { errors: [ e.message ], fields: {} }, status: :unprocessable_entity
          end

          private

          def authenticate_executor
            token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
            @executor = ::Initiatives::Executor.authenticate(token)
            return request_authentication unless @executor

            @executor.seen!(version: params[:version])
          end
        end
      end
    end
  end
end
