module Mentoring
  # Nota de 1 a 5 dada a uma competência numa data (uma autoavaliação é o conjunto de notas da data).
  class Rating < ApplicationRecord
    include TextGuards

    belongs_to :competency

    normalizes :comment, with: ->(value) { value.to_s.strip.presence }

    validates :rated_on, presence: true, uniqueness: { scope: :competency_id }
    validates :score, numericality: { only_integer: true, in: 1..5 }
    validates :comment, length: { maximum: 1000 }
  end
end
