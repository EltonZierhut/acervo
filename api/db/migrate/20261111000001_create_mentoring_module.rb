# Módulo Mentoria: acompanhamento de quem recebe mentoria (spec 010).
class CreateMentoringModule < ActiveRecord::Migration[8.0]
  def change
    create_table :mentoring_mentorships do |t|
      t.string :mentor_name, null: false
      t.string :topic
      t.text :description
      t.date :started_on, null: false
      t.date :ended_on
      t.string :cadence
      t.string :status, null: false, default: "active"
      t.timestamps
      t.check_constraint "status IN ('active', 'paused', 'finished')", name: "mentoring_mentorships_status_valid"
    end

    create_table :mentoring_questions do |t|
      t.references :mentorship, null: false, index: false, foreign_key: { to_table: :mentoring_mentorships, on_delete: :cascade }
      t.integer :position, null: false
      t.text :prompt, null: false
      t.text :answer
      t.timestamps
    end
    add_index :mentoring_questions, %i[mentorship_id position]

    create_table :mentoring_goals do |t|
      t.references :mentorship, null: false, foreign_key: { to_table: :mentoring_mentorships, on_delete: :cascade }
      t.string :title, null: false
      t.text :success_criteria
      t.text :description
      t.date :target_on
      t.string :status, null: false, default: "not_started"
      t.integer :progress, null: false, default: 0
      t.timestamps
      t.check_constraint "status IN ('not_started', 'in_progress', 'achieved', 'dropped')", name: "mentoring_goals_status_valid"
      t.check_constraint "progress BETWEEN 0 AND 100", name: "mentoring_goals_progress_range"
    end

    create_table :mentoring_meetings do |t|
      t.references :mentorship, null: false, index: false, foreign_key: { to_table: :mentoring_mentorships, on_delete: :cascade }
      t.date :held_on, null: false
      t.text :agenda
      t.text :notes
      t.text :takeaways
      t.integer :rating
      t.string :tags, array: true, null: false, default: []
      t.virtual :tags_text, type: :text, stored: true, as: "immutable_array_to_string(tags::text[], ' ')"
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(agenda, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(takeaways, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(notes, '')), 'C')
      SQL
      t.timestamps
      t.check_constraint "rating BETWEEN 1 AND 5", name: "mentoring_meetings_rating_range"
    end
    add_index :mentoring_meetings, %i[mentorship_id held_on]
    add_index :mentoring_meetings, :searchable, using: :gin

    create_table :mentoring_action_items do |t|
      t.references :mentorship, null: false, foreign_key: { to_table: :mentoring_mentorships, on_delete: :cascade }
      t.references :meeting, foreign_key: { to_table: :mentoring_meetings, on_delete: :nullify }
      t.references :goal, foreign_key: { to_table: :mentoring_goals, on_delete: :nullify }
      t.string :title, null: false
      t.date :due_on
      t.datetime :completed_at
      t.timestamps
    end

    create_table :mentoring_competencies do |t|
      t.references :mentorship, null: false, index: false, foreign_key: { to_table: :mentoring_mentorships, on_delete: :cascade }
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :mentoring_competencies, "mentorship_id, lower(name)", unique: true,
              name: "index_mentoring_competencies_on_mentorship_and_lower_name"

    create_table :mentoring_ratings do |t|
      t.references :competency, null: false, index: false, foreign_key: { to_table: :mentoring_competencies, on_delete: :cascade }
      t.date :rated_on, null: false
      t.integer :score, null: false
      t.text :comment
      t.timestamps
      t.check_constraint "score BETWEEN 1 AND 5", name: "mentoring_ratings_score_range"
    end
    add_index :mentoring_ratings, %i[competency_id rated_on], unique: true
  end
end
