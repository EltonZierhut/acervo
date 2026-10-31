module Initiatives
  # Entrega ou fase de uma iniciativa ("Protótipo jogável", "Go-live").
  class Milestone < ApplicationRecord
    include TextGuards
    belongs_to :initiative, class_name: "Initiatives::Initiative", touch: true
    has_many :tasks, class_name: "Initiatives::Task", dependent: :nullify

    normalizes :title, with: ->(value) { value.strip }
    normalizes :description, with: ->(value) { value.presence }

    validates :title, presence: true, length: { maximum: 200 }

    scope :ordered, -> { order(Arel.sql("#{table_name}.due_on ASC NULLS LAST"), :created_at, :id) }

    def self.progress_for(ids)
      Task.progress_by(:milestone_id, ids)
    end

    def completed?
      completed_at.present?
    end

    # A interface envia só "completed"; a data de conclusão é registrada aqui.
    def completed=(value)
      self.completed_at = ActiveModel::Type::Boolean.new.cast(value) ? (completed_at || Time.current) : nil
    end

    def overdue?
      !completed? && due_on.present? && due_on < Date.current
    end
  end
end
