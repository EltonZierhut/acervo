module Api
  module V1
    module Initiatives
      class ContextsController < ApplicationController
        before_action :set_context, only: %i[update destroy]

        # GET /api/v1/initiatives/contexts
        def index
          counts = ::Initiatives::Initiative.where.not(context_id: nil).group(:context_id).count
          render json: ::Initiatives::Context.ordered.map { |context| serialize(context, counts.fetch(context.id, 0)) }
        end

        def create
          context = ::Initiatives::Context.new(context_params)
          context.save ? render(json: serialize(context), status: :created) : render_errors(context)
        end

        def update
          @context.update(context_params) ? render(json: serialize(@context)) : render_errors(@context)
        end

        def destroy
          @context.destroy
          head :no_content
        end

        private

        def set_context
          @context = ::Initiatives::Context.find(params[:id])
        end

        def context_params
          params.require(:context).permit(:name, :color)
        end

        def serialize(context, count = nil)
          context.as_json(only: %i[id name color])
            .merge(initiatives_count: count || context.initiatives.count)
        end
      end
    end
  end
end
