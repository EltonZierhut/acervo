class CreateInitiativesRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :initiatives_runs do |t|
      t.references :task, null: false, foreign_key: { to_table: :initiatives_tasks, on_delete: :cascade }, index: false
      t.string :repository, null: false
      t.string :status, null: false, default: "queued"
      t.datetime :enqueued_at, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :last_heartbeat_at
      t.string :failure_kind
      t.text :failure_reason
      t.text :summary
      t.string :pull_request_url
      t.string :branch
      t.timestamps

      t.check_constraint "status IN ('queued', 'running', 'waiting', 'pr_open', 'no_changes', 'failed', 'canceled')",
        name: "initiatives_runs_status_check"
    end
    add_index :initiatives_runs, %i[task_id id]
    add_index :initiatives_runs, %i[status enqueued_at]
    # Uma execução ativa por tarefa e uma em andamento no sistema inteiro (FR-009).
    add_index :initiatives_runs, :task_id, unique: true, where: "status IN ('queued', 'running', 'waiting')",
      name: "index_initiatives_runs_one_active_per_task"
    add_index :initiatives_runs, :status, unique: true, where: "status = 'running'",
      name: "index_initiatives_runs_one_running"

    create_table :initiatives_run_questions do |t|
      t.references :run, null: false, foreign_key: { to_table: :initiatives_runs, on_delete: :cascade }
      t.text :body, null: false
      t.text :answer
      t.datetime :answered_at
      t.timestamps
    end
  end
end
