module Flashcards
  class Deck < ApplicationRecord
    DESCRIPTION_MAX_BYTES = 10.kilobytes
    LIMIT_RANGE = (0..9999)

    has_many :notes, dependent: nil # o banco apaga notas, cartões e revisões em cascata

    validates :name, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
    validates :new_per_day, :reviews_per_day, numericality: { only_integer: true, in: LIMIT_RANGE }
    validate :description_within_limit
    validate :no_null_bytes

    normalizes :name, with: ->(value) { value.to_s.strip }
    normalizes :description, with: ->(value) { value.presence }

    scope :alphabetical, -> { order(Arel.sql("lower(flashcards_decks.name)"), :id) }

    private

    def description_within_limit
      errors.add(:description, "passa do limite de 10 KB") if description.to_s.bytesize > DESCRIPTION_MAX_BYTES
    end

    def no_null_bytes
      errors.add(:base, "tem caracteres inválidos") if [ name, description ].any? { |value| value.to_s.include?("\0") }
    end
  end
end
