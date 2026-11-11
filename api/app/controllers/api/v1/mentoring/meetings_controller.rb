module Api
  module V1
    module Mentoring
      class MeetingsController < ApplicationController
        include Serialization

        before_action :set_meeting, only: %i[show update destroy]

        # GET /api/v1/mentoring/mentorships/:mentorship_id/meetings?q=termo&page=1
        def index
          mentorship = find_mentorship
          scope = mentorship.meetings.recent_first
          scope = scope.search(params[:q]) if params[:q].present?

          page = paginate(scope)
          meetings = page[:records].to_a
          meetings.each { |meeting| meeting.association(:mentorship).target = mentorship }
          progress = action_progress(:meeting_id, meetings.map(&:id))
          render json: { data: meetings.map { |m| serialize_meeting(m, progress.fetch(m.id)) }, meta: page[:meta] }
        end

        def show
          render json: serialize_meeting(@meeting)
        end

        # Corpo vazio cria o encontro de hoje (atalho "Novo encontro").
        def create
          meeting = find_mentorship.meetings.new(meeting_params)
          meeting.save ? render(json: serialize_meeting(meeting), status: :created) : render_errors(meeting)
        end

        def update
          @meeting.update(meeting_params) ? render(json: serialize_meeting(@meeting)) : render_errors(@meeting)
        end

        def destroy
          @meeting.destroy
          head :no_content
        end

        private

        def set_meeting
          @meeting = ::Mentoring::Meeting.includes(:mentorship).find(params[:id])
        end

        def meeting_params
          params.fetch(:meeting, {}).permit(:held_on, :agenda, :notes, :takeaways, :rating, :tags, tags: [])
        end
      end
    end
  end
end
