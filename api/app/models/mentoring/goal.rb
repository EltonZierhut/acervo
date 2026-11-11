module Mentoring
  # Objetivo da mentoria, com critério de sucesso e progresso de 0 a 100.
  class Goal < ApplicationRecord
    include TextGuards

    STATUSES = %w[not_started in_progress achieved dropped].freeze

    belongs_to :mentorship
    has_many :action_items, dependent: nil # o banco limpa o vínculo (ON DELETE SET NULL)

    normalizes :title, with: ->(value) { value.to_s.strip }
    long_text :success_criteria, :description

    validates :title, presence: true, length: { maximum: 200 }
    validates :status, inclusion: { in: STATUSES }
    validates :progress, numericality: { only_integer: true, in: 0..100 }

    before_validation :sync_status_and_progress

    scope :counted, -> { where.not(status: "dropped") }
    # Abertos por prazo (sem prazo no fim), depois alcançados e abandonados.
    scope :ordered, lambda {
      order(Arel.sql("CASE #{table_name}.status WHEN 'achieved' THEN 1 WHEN 'dropped' THEN 2 ELSE 0 END"),
            Arel.sql("#{table_name}.target_on ASC NULLS LAST"), :id)
    }

    def overdue?
      target_on.present? && target_on < Date.current && %w[not_started in_progress].include?(status)
    end

    private

    # "Alcançado" vale 100%; mexer no progresso de um objetivo não iniciado o coloca em andamento.
    def sync_status_and_progress
      if status == "achieved"
        self.progress = 100
      elsif status == "not_started" && progress.to_i.positive? && will_save_change_to_progress?
        self.status = "in_progress"
      end
    end
  end
end
