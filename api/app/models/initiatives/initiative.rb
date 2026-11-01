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
    REPOSITORY_STATUSES = { unverified: "unverified", valid: "valid", invalid: "invalid" }.freeze
    REPOSITORY_FORMAT = %r{\A[A-Za-z0-9][A-Za-z0-9-]*/(?!\.+\z)[A-Za-z0-9._-]+\z}

    # O enum também cria os escopos "active", "done", "not_done" etc.
    enum :status, STATUSES, default: :planned, validate: true
    enum :priority, Initiatives::PRIORITIES, default: :medium, validate: true, prefix: :priority
    enum :repository_status, REPOSITORY_STATUSES, default: :unverified, validate: true, prefix: :repository

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

    # Aceita "owner/name" ou o endereço copiado do GitHub. Vazio remove a conexão.
    normalizes :github_repository, with: lambda { |value|
      value.to_s.strip.sub(%r{\A(?:https?://(?:www\.)?github\.com/|git@github\.com:)}i, "")
        .sub(%r{/\z}, "").sub(/\.git\z/i, "").presence
    }

    validates :name, presence: true, length: { maximum: 200 }
    validates :github_repository, format: { with: REPOSITORY_FORMAT, message: "precisa estar no formato dono/repositório" },
                                  length: { maximum: 200 }, allow_nil: true
    validate :due_on_not_before_starts_on
    validate :sections_are_known
    validate :context_exists

    before_save :reset_repository_check, if: :github_repository_changed?

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

    # Volta para "não verificado"; o executor confere na próxima consulta.
    def request_repository_check!
      update!(repository_status: :unverified, repository_error: nil, repository_checked_at: nil)
    end

    private

    def reset_repository_check
      self.repository_status = :unverified
      self.repository_error = nil
      self.repository_checked_at = nil
    end

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
