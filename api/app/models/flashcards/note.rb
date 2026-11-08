module Flashcards
  # O conteúdo escrito. Cada direção estudada vira um cartão (ordinal 0: frente → verso; 1: verso → frente).
  class Note < ApplicationRecord
    include Searchable
    include NormalizesTags

    TYPES = %w[basic basic_reversed].freeze
    TEXT_MAX_BYTES = 100.kilobytes

    searchable_partial_columns :front, :back, :tags_text

    belongs_to :deck
    has_many :cards, -> { order(:ordinal) }, dependent: nil # cartões e revisões saem em cascata no banco

    validates :front, :back, presence: true
    validates :note_type, inclusion: { in: TYPES }
    validate :texts_within_limit
    validate :no_null_bytes

    after_save :sync_cards

    scope :with_tag, ->(tag) { where("? = ANY(flashcards_notes.tags)", tag.to_s.strip.downcase) }

    def ordinals
      note_type == "basic_reversed" ? [ 0, 1 ] : [ 0 ]
    end

    # Volta os cartões a novos, mantendo o histórico de revisões.
    def reset!
      Card.where(note_id: id).update_all(state: "new", due_at: nil, interval_days: 0, ease: Scheduler::STARTING_EASE,
                                         step_index: 0, updated_at: Time.current)
      cards.reset
    end

    private

    # Cria ou remove só o cartão que mudou, para não perder o agendamento do outro.
    def sync_cards
      existing = Card.where(note_id: id)
      existing.where.not(ordinal: ordinals).delete_all
      (ordinals - existing.pluck(:ordinal)).each { |ordinal| Card.create!(note_id: id, ordinal:) }
      cards.reset
    end

    def texts_within_limit
      %i[front back].each do |field|
        errors.add(field, "passa do limite de 100 KB") if self[field].to_s.bytesize > TEXT_MAX_BYTES
      end
    end

    # O PostgreSQL não guarda o caractere nulo em texto.
    def no_null_bytes
      errors.add(:base, "tem caracteres inválidos") if [ front, back, *tags ].any? { |value| value.to_s.include?("\0") }
    end
  end
end
