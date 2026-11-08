module Api
  module V1
    module Flashcards
      # Estudo um cartão por vez: a resposta já traz o próximo, sem fila no frontend (research.md).
      class StudyController < ApplicationController
        include Serialization

        # GET /api/v1/flashcards/decks/:deck_id/study
        def show
          deck = ::Flashcards::Deck.find(params[:deck_id])
          render json: study_payload(deck)
        end

        # POST /api/v1/flashcards/cards/:id/review  { rating: 1..4, duration_ms: 1234 }
        def review
          card = ::Flashcards::Card.includes(note: :deck).find(params[:id])
          rating = Integer(params[:rating], exception: false)

          unless ::Flashcards::Scheduler::RATINGS.cover?(rating)
            return render json: { errors: [ "Resposta precisa ser de 1 a 4" ], fields: { rating: [ "precisa ser de 1 a 4" ] } },
                          status: :unprocessable_entity
          end
          if card.note.suspended?
            return render json: { errors: [ "Nota suspensa" ], fields: {} }, status: :unprocessable_entity
          end

          now = Time.current
          card.answer!(rating, now:, duration_ms: params[:duration_ms])
          render json: study_payload(card.note.deck, now:)
        end
      end
    end
  end
end
