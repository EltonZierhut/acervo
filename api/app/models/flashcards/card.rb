module Flashcards
  class Card < ApplicationRecord
    STATES = %w[new learning review relearning].freeze

    belongs_to :note
    has_many :reviews, -> { order(:reviewed_at) }, dependent: nil

    validates :state, inclusion: { in: STATES }
    validates :ordinal, inclusion: { in: [ 0, 1 ] }

    # Cartões que podem aparecer no estudo de um baralho.
    scope :studyable_in, ->(deck_id) { joins(:note).where(flashcards_notes: { deck_id:, suspended: false }) }
    scope :in_steps, -> { where(state: %w[learning relearning]) }

    def question
      ordinal.zero? ? note.front : note.back
    end

    def answer
      ordinal.zero? ? note.back : note.front
    end

    # Registra a resposta, reagenda o cartão e guarda a revisão no histórico.
    def answer!(rating, now: Time.current, duration_ms: nil, scheduler: Scheduler.new(now:))
      result = scheduler.answer(self, rating)
      before = { state_before: state, interval_before: state == "review" ? interval_days : 0 }

      transaction do
        update!(state: result.state, step_index: result.step_index, interval_days: result.interval_days,
                ease: result.ease, lapses: result.lapses, due_at: result.due_at, reps: reps + 1, last_reviewed_at: now)
        Review.create!(card: self, rating: Integer(rating), **before,
                       interval_after: result.in_steps? ? 0 : result.interval_days,
                       ease_after: result.ease, duration_ms:, reviewed_at: now)
      end
      result
    end
  end
end
