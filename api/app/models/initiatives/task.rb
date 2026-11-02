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

    searchable_partial_columns :title, :description_text

    normalizes :title, with: ->(value) { value.strip }
    # HTML sanitizado; texto puro vira parágrafos. A busca usa description_text, gerado a partir dele.
    normalizes :description, with: ->(value) { RichText.clean(value) }

    validates :title, presence: true, length: { maximum: 300 }
    validate :milestone_from_same_initiative

    before_save :assign_number
    before_save :sync_completed_at
    before_save :sync_description_text
    before_save :append_to_column, if: -> { (new_record? || status_changed?) && !@placing }
    after_update :cancel_pending_runs, if: -> { saved_change_to_status? && done? }

    scope :in_milestone, ->(id) { id.to_s == "none" ? where(milestone_id: nil) : where(milestone_id: id) }
    # Fazendo, a fazer, concluídas; dentro de cada coluna, a ordem do quadro.
    scope :ordered, lambda {
      order(
        Arel.sql(sanitize_sql_array([ "array_position(ARRAY[?]::varchar[], #{table_name}.status)", STATUS_ORDER ])),
        :position, :id
      )
    }

    # { valor da coluna => { done:, total: } } para os ids informados.
    def self.progress_by(column, ids)
      where(column => ids).group(column)
        .pluck(column, Arel.sql("count(*)"), Arel.sql("count(*) FILTER (WHERE status = 'done')"))
        .to_h { |id, total, done| [ id, { done:, total: } ] }
    end

    # Move para uma coluna e uma posição (índice a partir de 0) numa só operação. Com before_id,
    # a tarefa fica antes dela (útil quando filtros escondem cards da coluna); sem a posição,
    # vai para o fim. As demais tarefas da coluna são renumeradas.
    def move_to(new_status, index: nil, before_id: nil)
      transaction do
        initiative.lock!
        @placing = true
        self.status = new_status
        save!
        ids = initiative.tasks.where(status: new_status).where.not(id: id).order(:position, :id).pluck(:id)
        at = before_id.present? && ids.index(before_id.to_i) || index || ids.size
        ids.insert(at.to_i.clamp(0, ids.size), id)
        self.class.where(id: ids)
          .update_all(self.class.sanitize_sql_array([ "position = array_position(ARRAY[?]::bigint[], id) - 1", ids ]))
        reload
      end
    ensure
      @placing = false
    end

    def overdue?
      !done? && due_on.present? && due_on < Date.current
    end

    private

    # Tarefa concluída à mão não precisa mais ser executada. A que já está rodando segue até o fim.
    def cancel_pending_runs
      runs.where(status: %w[queued waiting]).find_each(&:cancel!)
    end

    # Número da tarefa dentro da iniciativa (#12). O bloqueio evita dois números iguais em criações simultâneas.
    def assign_number
      return if number

      initiative.lock!
      self.number = (initiative.tasks.maximum(:number) || 0) + 1
    end

    def append_to_column
      self.position = (initiative.tasks.where(status:).where.not(id:).maximum(:position) || -1) + 1
    end

    def sync_description_text
      self.description_text = RichText.to_plain_text(description).presence if description_changed? || new_record?
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
