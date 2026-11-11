module Mentoring
  # Ação combinada, com prazo; pode vir de um encontro e servir a um objetivo da mesma mentoria.
  class ActionItem < ApplicationRecord
    include TextGuards

    belongs_to :mentorship
    belongs_to :meeting, optional: true
    belongs_to :goal, optional: true

    normalizes :title, with: ->(value) { value.to_s.strip }

    validates :title, presence: true, length: { maximum: 200 }
    validate :links_in_same_mentorship

    scope :pending, -> { where(completed_at: nil) }
    scope :completed, -> { where.not(completed_at: nil) }
    scope :overdue, -> { pending.where(due_on: ...Date.current) }
    # Abertas por prazo (sem prazo no fim), depois as concluídas mais recentes.
    scope :ordered, lambda {
      order(Arel.sql("#{table_name}.completed_at IS NOT NULL"),
            Arel.sql("CASE WHEN #{table_name}.completed_at IS NULL THEN #{table_name}.due_on END ASC NULLS LAST"),
            Arel.sql("#{table_name}.completed_at DESC NULLS LAST"), :id)
    }

    def done?
      completed_at.present?
    end

    # A interface envia só "done"; a data da conclusão é registrada aqui.
    def done=(value)
      self.completed_at = ActiveModel::Type::Boolean.new.cast(value) ? (completed_at || Time.current) : nil
    end

    def overdue?
      !done? && due_on.present? && due_on < Date.current
    end

    private

    def links_in_same_mentorship
      errors.add(:meeting, "precisa ser desta mentoria") if meeting && meeting.mentorship_id != mentorship_id
      errors.add(:goal, "precisa ser desta mentoria") if goal && goal.mentorship_id != mentorship_id
    end
  end
end
