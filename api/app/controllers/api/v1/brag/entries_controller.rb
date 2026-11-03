module Api
  module V1
    module Brag
      class EntriesController < ApplicationController
        before_action :set_entry, only: %i[show update destroy]

        # GET /api/v1/brag/entries?q=termo&category=x&tag=y&year=2026&page=1
        def index
          scope = ::Brag::Entry.order(achieved_on: :desc, id: :desc)
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.in_category(params[:category]) if params[:category].present?
          scope = scope.with_tag(params[:tag]) if params[:tag].present?
          scope = scope.in_year(params[:year]) if params[:year].to_s.match?(/\A\d{4}\z/)

          page = paginate(scope)
          render json: { data: page[:records].map { |e| serialize(e) }, meta: page[:meta] }
        end

        def show
          render json: serialize(@entry)
        end

        def create
          entry = ::Brag::Entry.new(entry_params)
          entry.achieved_on ||= Date.current
          entry.save ? render(json: serialize(entry), status: :created) : render_errors(entry)
        end

        def update
          @entry.update(entry_params) ? render(json: serialize(@entry)) : render_errors(@entry)
        end

        def destroy
          @entry.destroy
          head :no_content
        end

        private

        def set_entry
          @entry = ::Brag::Entry.find(params[:id])
        end

        def entry_params
          params.require(:entry).permit(:title, :achieved_on, :description, :category, :impact, :metrics,
                                        :project, :tags, :evidence_links, tags: [], evidence_links: [])
        end

        def serialize(entry)
          entry.as_json(only: %i[id title achieved_on description category tags impact metrics
                                 evidence_links project created_at updated_at])
        end
      end
    end
  end
end
