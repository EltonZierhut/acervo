module Initiatives
  class Task < ApplicationRecord
    include TextGuards
    include Searchable

    STATUSES = { todo: "todo", doing: "doing", done: "done" }.freeze
    STATUS_ORDER = %w[doing todo done].freeze

    enum :status, STATUSES, default: :todo, validate: true
    enum :priority, Initiatives::PRIORITIES, default: :medium, validate: true, prefix: :priority

    belongs_to :initiative, class_name: "Initiatives::Initiative", touch: true
    belongs_to :milestone, class_name: "Initiatives::Milestone", optional: true
    # Imagens, links e execuções são apagados pelo banco (ON DELETE CASCADE).
    has_many :images, class_name: "Initiatives::TaskImage"
    has_many :links, class_name: "Initiatives::TaskLink"
    has_many :runs, class_name: "Initiatives::Run"

    searchable_partial_columns :title, :description

    normalizes :title, with: ->(value) { value.strip }
    normalizes :description, with: ->(value) { value.presence }

    validates :title, presence: true, length: { maximum: 300 }
    validate :milestone_from_same_initiative

    before_save :sync_completed_at
    after_update :cancel_pending_runs, if: -> { saved_change_to_status? && done? }

    scope :in_milestone, ->(id) { id.to_s == "none" ? where(milestone_id: nil) : where(milestone_id: id) }
    # Fazendo, a fazer, concluídas; abertas por prazo, concluídas pela conclusão mais recente.
    scope :ordered, lambda {
      order(
        Arel.sql(sanitize_sql_array([ "array_position(ARRAY[?]::varchar[], #{table_name}.status)", STATUS_ORDER ])),
        Arel.sql("CASE WHEN #{table_name}.status = 'done' THEN NULL ELSE #{table_name}.due_on END ASC NULLS LAST"),
        Arel.sql("#{table_name}.completed_at DESC NULLS LAST"),
        :created_at, :id
      )
    }

    # { valor da coluna => { done:, total: } } para os ids informados.
    def self.progress_by(column, ids)
      where(column => ids).group(column)
        .pluck(column, Arel.sql("count(*)"), Arel.sql("count(*) FILTER (WHERE status = 'done')"))
        .to_h { |id, total, done| [ id, { done:, total: } ] }
    end

    def overdue?
      !done? && due_on.present? && due_on < Date.current
    end

    private

    # Tarefa concluída à mão não precisa mais ser executada. A que já está rodando segue até o fim.
    def cancel_pending_runs
      runs.where(status: %w[queued waiting]).find_each(&:cancel!)
    end

    def sync_completed_at
      self.completed_at = done? ? (completed_at || Time.current) : nil
    end

    def milestone_from_same_initiative
      return if milestone_id.blank?
      return if milestone && milestone.initiative_id == initiative_id

      errors.add(:milestone_id, "precisa ser um marco desta iniciativa")
    end
  end
end
