module Api
  module V1
    module Flashcards
      class DecksController < ApplicationController
        include Serialization

        before_action :set_deck, only: %i[show update destroy]

        # GET /api/v1/flashcards/decks — todos, em ordem alfabética, com as contagens do dia.
        def index
          render json: { data: serialize_decks(::Flashcards::Deck.alphabetical) }
        end

        def show
          render json: serialize_decks([ @deck ]).first
        end

        def create
          deck = ::Flashcards::Deck.new(deck_params)
          deck.save ? render(json: serialize_decks([ deck ]).first, status: :created) : render_errors(deck)
        end

        def update
          @deck.update(deck_params) ? render(json: serialize_decks([ @deck ]).first) : render_errors(@deck)
        end

        def destroy
          @deck.destroy
          head :no_content
        end

        private

        def set_deck
          @deck = ::Flashcards::Deck.find(params[:id])
        end

        def deck_params
          params.require(:deck).permit(:name, :description, :new_per_day, :reviews_per_day)
        end
      end
    end
  end
end
