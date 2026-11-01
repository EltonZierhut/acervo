module Initiatives
  # Uma tentativa de desenvolver uma tarefa. A tabela é a própria fila.
  # Transições: specs/006-ai-task-automation/data-model.md
  class Run < ApplicationRecord
    STATUSES = { queued: "queued", running: "running", waiting: "waiting", pr_open: "pr_open",
                 no_changes: "no_changes", failed: "failed", canceled: "canceled" }.freeze
    ACTIVE_STATUSES = %w[queued running waiting].freeze
    REPORTABLE_STATUSES = %w[pr_open no_changes failed].freeze
    FAILURE_KINDS = %w[interrupted timeout repository agent workflow_change other].freeze
    STALE_AFTER = 5.minutes

    class InvalidTransition < StandardError; end

    enum :status, STATUSES, default: :queued, validate: true

    belongs_to :task, class_name: "Initiatives::Task"
    has_many :questions, class_name: "Initiatives::RunQuestion"

    scope :active, -> { where(status: ACTIVE_STATUSES) }
    scope :search_task, ->(term) { where(task_id: Task.search(term).unscope(:order).select(:id)) }
    # Ativas por ordem de chegada; depois as encerradas, mais recentes primeiro.
    scope :for_queue, lambda {
      active = sanitize_sql_array([ "status IN (?)", ACTIVE_STATUSES ])
      order(Arel.sql("CASE WHEN #{active} THEN 0 ELSE 1 END"),
            Arel.sql("CASE WHEN #{active} THEN enqueued_at END ASC"),
            Arel.sql("COALESCE(finished_at, created_at) DESC"), id: :desc)
    }

    validates :repository, presence: true, on: :update
    validates :failure_kind, inclusion: { in: FAILURE_KINDS }, allow_nil: true
    validate :task_can_be_enqueued, on: :create

    # { task_id => execução mais recente }
    def self.latest_by_task(task_ids)
      where(task_id: task_ids).select("DISTINCT ON (task_id) initiatives_runs.*").order(:task_id, id: :desc).index_by(&:task_id)
    end

    # Devolve a execução, com erros de validação se não puder entrar na fila.
    def self.enqueue(task)
      run = new(task:, repository: task.initiative.github_repository, enqueued_at: Time.current)
      run.save
      run
    rescue ActiveRecord::RecordNotUnique
      run.errors.add(:base, "A tarefa já está na fila ou em execução")
      run
    end

    # Próxima da fila, ou nil se não houver ou se outra já estiver em andamento.
    def self.claim
      expire_stale!
      transaction do
        next nil if running.exists?

        run = queued.order(:enqueued_at, :id).lock("FOR UPDATE SKIP LOCKED").first
        run&.update!(status: :running, started_at: Time.current, last_heartbeat_at: Time.current)
        run
      end
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    # Sem tarefas agendadas no servidor: roda quando a fila é consultada.
    def self.expire_stale!
      running.where(last_heartbeat_at: ...STALE_AFTER.ago).find_each do |run|
        run.update!(status: :failed, finished_at: Time.current, failure_kind: "interrupted",
                    failure_reason: "O executor parou de responder durante a execução. Envie a tarefa de novo.")
      end
    end

    def active? = ACTIVE_STATUSES.include?(status)

    # Devolve true se o executor deve parar.
    def heartbeat!
      return true unless running?

      update!(last_heartbeat_at: Time.current)
      false
    end

    def cancel!
      with_lock do
        next false unless active?

        update!(status: :canceled, finished_at: Time.current)
        true
      end
    end

    def ask!(bodies)
      with_lock do
        raise InvalidTransition unless running?

        bodies.each { |body| questions.create!(body:) }
        update!(status: :waiting)
      end
    end

    # { question_id => resposta }. Volta para a fila, na posição original, quando não falta nenhuma.
    def answer!(answers)
      with_lock do
        raise InvalidTransition unless waiting?

        answers.each do |question_id, text|
          question = questions.pending.find(question_id)
          question.update!(answer: text.to_s.strip.presence || raise(ArgumentError, "Escreva a resposta"), answered_at: Time.current)
        end
        update!(status: :queued, started_at: nil, last_heartbeat_at: nil) unless questions.pending.exists?
      end
    end

    # Resultado informado pelo executor. Repetir o mesmo resultado não muda nada.
    def complete!(status:, summary: nil, branch: nil, pull_request_url: nil, failure_kind: nil, failure_reason: nil)
      raise ArgumentError, "Resultado inválido" unless REPORTABLE_STATUSES.include?(status)
      raise ArgumentError, "Endereço do PR inválido" unless valid_pull_request_url?(status, pull_request_url)

      with_lock do
        next if self.status == status

        if canceled?
          # Cancelada depois de o PR abrir: guarda o link para não perder a referência.
          update!(pull_request_url:, branch:) if pull_request_url.present?
          next
        end
        # O PR abriu, mas o aviso atrasou e o servidor já tinha dado a execução como interrompida.
        late_pr = failed? && failure_kind_was_interrupted? && status == "pr_open"
        raise InvalidTransition unless running? || late_pr

        update!(self.class.result_attributes(status, summary, branch, pull_request_url, failure_kind, failure_reason))
        task.update!(status: :doing) if pr_open? && task.todo?
      end
    end

    def self.result_attributes(status, summary, branch, pull_request_url, failure_kind, failure_reason)
      failed = status == "failed"
      { status:, summary:, branch:, pull_request_url:, finished_at: Time.current,
        failure_kind: failed ? (failure_kind.presence || "other") : nil,
        failure_reason: failed ? (failure_reason.presence || "A execução falhou sem informar o motivo.") : nil }
    end

    private

    def failure_kind_was_interrupted? = failure_kind == "interrupted"

    def valid_pull_request_url?(status, url)
      return url.blank? || url_of_this_repository?(url) unless status == "pr_open"

      url_of_this_repository?(url)
    end

    def url_of_this_repository?(url)
      url.to_s.match?(%r{\Ahttps://github\.com/#{Regexp.escape(repository)}/pull/\d+\z}i)
    end

    def task_can_be_enqueued
      return unless task

      errors.add(:base, "Escreva a descrição da tarefa antes de enviar para a fila") if task.description.blank?
      errors.add(:base, "Tarefa concluída não pode ir para a fila") if task.done?
      errors.add(:base, "Conecte a iniciativa a um repositório antes de enviar para a fila") if repository.blank?
      errors.add(:base, "O repositório da iniciativa está sem acesso") if task.initiative.repository_invalid?
      errors.add(:base, "A tarefa já está na fila ou em execução") if task.runs.active.exists?
    end
  end
end
