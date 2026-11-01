module Api
  module V1
    module Initiatives
      class ExecutorStatusController < ApplicationController
        def show
          executor = ::Initiatives::Executor.first
          render json: { configured: executor.present?, available: executor&.available? || false,
                         last_seen_at: executor&.last_seen_at }
        end
      end
    end
  end
end
