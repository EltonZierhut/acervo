module Mentoring
  # Uma mentoria recebida: o mentor, o tema e o período.
  class Mentorship < ApplicationRecord
    include TextGuards

    STATUSES = %w[active paused finished].freeze

    # O banco apaga os filhos em cascata (ON DELETE CASCADE).
    has_many :questions, -> { order(:position, :id) }, dependent: nil
    has_many :goals, dependent: nil
    has_many :meetings, dependent: nil
    has_many :action_items, dependent: nil
    has_many :competencies, -> { order(:position, :id) }, dependent: nil

    normalizes :mentor_name, with: ->(value) { value.to_s.strip }
    normalizes :topic, :cadence, with: ->(value) { value.to_s.strip.presence }
    long_text :description

    attribute :started_on, :date, default: -> { Date.current }

    validates :mentor_name, presence: true, length: { maximum: 100 }
    validates :topic, length: { maximum: 200 }
    validates :cadence, length: { maximum: 100 }
    validates :status, inclusion: { in: STATUSES }
    validates :started_on, presence: true
    validate :ends_after_start

    # Ativas, pausadas e encerradas; dentro de cada uma, as mais recentes primeiro.
    scope :listed, lambda {
      order(Arel.sql("CASE #{table_name}.status WHEN 'active' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END"),
            started_on: :desc, id: :desc)
    }

    def add_suggested_questions!
      SuggestedQuestions::ALL.each_with_index do |prompt, index|
        questions.create!(prompt:, position: index + 1)
      end
    end

    private

    def ends_after_start
      return if ended_on.blank? || started_on.blank? || ended_on >= started_on

      errors.add(:ended_on, "não pode ser antes do início")
    end
  end
end
