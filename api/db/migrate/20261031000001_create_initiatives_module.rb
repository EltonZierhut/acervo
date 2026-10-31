# Módulo Iniciativas (feature 005): contextos, iniciativas, marcos e tarefas.
class CreateInitiativesModule < ActiveRecord::Migration[8.0]
  def change
    create_table :initiatives_contexts do |t|
      t.string :name, null: false
      t.string :color, null: false, default: "#6b7380"
      t.timestamps
    end
    add_index :initiatives_contexts, "lower(name)", unique: true, name: "index_initiatives_contexts_on_lower_name"

    create_table :initiatives_initiatives do |t|
      t.references :context, foreign_key: { to_table: :initiatives_contexts, on_delete: :nullify }
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "planned"
      t.string :priority, null: false, default: "medium"
      t.date :starts_on
      t.date :due_on
      t.string :tags, array: true, null: false, default: []
      t.string :sections, array: true, null: false, default: %w[tasks milestones]
      t.virtual :tags_text, type: :text, stored: true, as: "immutable_array_to_string(tags::text[], ' ')"
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(description, '')), 'B')
      SQL
      t.timestamps

      t.check_constraint "status IN ('idea', 'planned', 'active', 'paused', 'done')", name: "initiatives_status_check"
      t.check_constraint "priority IN ('low', 'medium', 'high')", name: "initiatives_priority_check"
      t.check_constraint "due_on IS NULL OR starts_on IS NULL OR due_on >= starts_on", name: "initiatives_dates_check"
    end
    add_index :initiatives_initiatives, :status
    add_index :initiatives_initiatives, :searchable, using: :gin
    add_index :initiatives_initiatives, :tags, using: :gin
    add_index :initiatives_initiatives, :name, using: :gin, opclass: :gin_trgm_ops,
      name: "index_initiatives_initiatives_on_name_trgm"

    create_table :initiatives_milestones do |t|
      t.references :initiative, null: false, index: false,
        foreign_key: { to_table: :initiatives_initiatives, on_delete: :cascade }
      t.string :title, null: false
      t.text :description
      t.date :due_on
      t.datetime :completed_at
      t.timestamps
    end
    add_index :initiatives_milestones, %i[initiative_id due_on]

    create_table :initiatives_tasks do |t|
      t.references :initiative, null: false, index: false,
        foreign_key: { to_table: :initiatives_initiatives, on_delete: :cascade }
      t.references :milestone, foreign_key: { to_table: :initiatives_milestones, on_delete: :nullify }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "todo"
      t.string :priority, null: false, default: "medium"
      t.date :due_on
      t.datetime :completed_at
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(description, '')), 'B')
      SQL
      t.timestamps

      t.check_constraint "status IN ('todo', 'doing', 'done')", name: "initiatives_tasks_status_check"
      t.check_constraint "priority IN ('low', 'medium', 'high')", name: "initiatives_tasks_priority_check"
    end
    add_index :initiatives_tasks, %i[initiative_id status]
    add_index :initiatives_tasks, :searchable, using: :gin
    add_index :initiatives_tasks, :title, using: :gin, opclass: :gin_trgm_ops,
      name: "index_initiatives_tasks_on_title_trgm"
  end
end
