module Mentoring
  # Habilidade que o mentorado quer desenvolver e autoavalia de tempos em tempos.
  class Competency < ApplicationRecord
    include TextGuards

    belongs_to :mentorship
    has_many :ratings, -> { order(:rated_on) }, dependent: nil # o banco apaga as notas em cascata

    normalizes :name, with: ->(value) { value.to_s.strip }

    validates :name, presence: true, length: { maximum: 100 },
                     uniqueness: { scope: :mentorship_id, case_sensitive: false }
    validates :position, numericality: { only_integer: true, greater_than: 0 }

    before_validation :append_to_end, on: :create

    private

    def append_to_end
      return if position.present? || mentorship.nil?

      self.position = (mentorship.competencies.maximum(:position) || 0) + 1
    end
  end
end
