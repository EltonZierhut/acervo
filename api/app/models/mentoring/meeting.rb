module Mentoring
  # Encontro com o mentor: pauta, anotações, aprendizados e uma nota de 1 a 5.
  class Meeting < ApplicationRecord
    include TextGuards
    include Searchable
    include NormalizesTags

    belongs_to :mentorship
    has_many :action_items, dependent: nil # o banco limpa o vínculo (ON DELETE SET NULL)

    searchable_partial_columns :agenda, :notes, :takeaways, :tags_text

    long_text :agenda, :notes, :takeaways
    attribute :held_on, :date, default: -> { Date.current }

    validates :held_on, presence: true
    validates :rating, numericality: { only_integer: true, in: 1..5 }, allow_nil: true

    scope :recent_first, -> { order(held_on: :desc, id: :desc) }
    scope :held, -> { where(held_on: ..Date.current) }

    def held?
      held_on <= Date.current
    end
  end
end
