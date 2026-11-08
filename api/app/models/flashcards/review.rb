module Flashcards
  # Uma resposta dada a um cartão. Histórico imutável: base para estatísticas e para o FSRS (fase 3).
  class Review < ApplicationRecord
    MAX_DURATION_MS = 3_600_000

    belongs_to :card

    validates :rating, inclusion: { in: Scheduler::RATINGS }
    validates :state_before, inclusion: { in: Card::STATES }
    validates :reviewed_at, presence: true

    normalizes :duration_ms, with: ->(value) { value.to_i.clamp(0, MAX_DURATION_MS) }

    def readonly?
      persisted? || super
    end
  end
end
