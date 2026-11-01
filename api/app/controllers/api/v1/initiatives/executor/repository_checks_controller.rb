module Api
  module V1
    module Initiatives
      module Executor
        class RepositoryChecksController < BaseController
          def index
            repositories = ::Initiatives::Initiative.where(repository_status: "unverified")
              .where.not(github_repository: nil).distinct.pluck(:github_repository)
            render json: { repositories: }
          end

          def create
            valid = ActiveModel::Type::Boolean.new.cast(params[:valid])
            ::Initiatives::Initiative.where(github_repository: params[:repository].to_s).update_all(
              repository_status: valid ? "valid" : "invalid",
              repository_error: valid ? nil : params[:error].to_s.first(1_000).presence,
              repository_checked_at: Time.current
            )
            head :ok
          end
        end
      end
    end
  end
end
