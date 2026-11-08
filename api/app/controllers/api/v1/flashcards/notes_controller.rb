module Api
  module V1
    module Flashcards
      class NotesController < ApplicationController
        include Serialization

        before_action :set_note, only: %i[show update destroy reset]

        # GET /api/v1/flashcards/decks/:deck_id/notes?q=termo&tag=x&page=1
        def index
          deck = ::Flashcards::Deck.find(params[:deck_id])
          scope = deck.notes.includes(:cards).order(created_at: :desc, id: :desc)
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.with_tag(params[:tag]) if params[:tag].present?

          page = paginate(scope)
          render json: { data: page[:records].map { |note| serialize_note(note) }, meta: page[:meta] }
        end

        def show
          render json: serialize_note(@note)
        end

        def create
          deck = ::Flashcards::Deck.find(params[:deck_id])
          note = deck.notes.new(note_params.except(:deck_id, :suspended))
          note.save ? render(json: serialize_note(note), status: :created) : render_errors(note)
        end

        def update
          @note.update(note_params) ? render(json: serialize_note(@note)) : render_errors(@note)
        end

        # POST /api/v1/flashcards/notes/:id/reset — cartões voltam a novos; o histórico fica.
        def reset
          @note.reset!
          render json: serialize_note(@note)
        end

        def destroy
          @note.destroy
          head :no_content
        end

        private

        def set_note
          @note = ::Flashcards::Note.find(params[:id])
        end

        def note_params
          params.require(:note).permit(:note_type, :front, :back, :tags, :deck_id, :suspended, tags: [])
        end
      end
    end
  end
end
