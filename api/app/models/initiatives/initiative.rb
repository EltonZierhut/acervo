module Initiatives
  # Qualquer coisa com objetivo e etapas: um projeto do trabalho, um jogo, uma reforma.
  class Initiative < ApplicationRecord
    include TextGuards
    include Searchable
    include NormalizesTags

    STATUSES = { idea: "idea", planned: "planned", active: "active", paused: "paused", done: "done" }.freeze
    # Ordem da listagem: o que está em andamento primeiro.
    STATUS_ORDER = %w[active planned idea paused done].freeze
    # Seções (abas) disponíveis, na ordem em que aparecem. Novas fases ampliam esta lista.
    SECTIONS = %w[tasks milestones].freeze

    # O enum também cria os escopos "active", "done", "not_done" etc.
    enum :status, STATUSES, default: :planned, validate: true
    enum :priority, Initiatives::PRIORITIES, default: :medium, validate: true, prefix: :priority

    belongs_to :context, class_name: "Initiatives::Context", optional: true
    # Marcos e tarefas são apagados pelo banco (ON DELETE CASCADE).
    has_many :milestones, class_name: "Initiatives::Milestone"
    has_many :tasks, class_name: "Initiatives::Task"

    searchable_partial_columns :name, :description, :tags_text

    normalizes :name, with: ->(value) { value.strip }
    normalizes :description, with: ->(value) { value.presence }
    # Mantém a ordem de SECTIONS e preserva valores desconhecidos para a validação recusá-los.
    normalizes :sections, with: lambda { |value|
      values = Array(value).map { |section| section.to_s.strip }.reject(&:blank?).uniq
      (SECTIONS & values) + (values - SECTIONS)
    }

    validates :name, presence: true, length: { maximum: 200 }
    validate :due_on_not_before_starts_on
    validate :sections_are_known
    validate :context_exists

    scope :in_context, ->(id) { id.to_s == "none" ? where(context_id: nil) : where(context_id: id) }
    scope :ordered, lambda {
      order(Arel.sql(sanitize_sql_array(
        [ "array_position(ARRAY[?]::varchar[], #{table_name}.status)", STATUS_ORDER ]
      )), updated_at: :desc, id: :desc)
    }

    # { initiative_id => { done:, total: } } das tarefas, numa consulta só.
    def self.progress_for(ids)
      Task.progress_by(:initiative_id, ids)
    end

    private

    def due_on_not_before_starts_on
      return if starts_on.blank? || due_on.blank? || due_on >= starts_on

      errors.add(:due_on, "não pode ser anterior à data de início")
    end

    def sections_are_known
      unknown = Array(sections) - SECTIONS
      errors.add(:sections, "inválidas: #{unknown.join(', ')}") if unknown.any?
    end

    def context_exists
      errors.add(:context_id, "não existe") if context_id.present? && context.nil?
    end
  end
end
