# Módulo Flashcards: estudo por repetição espaçada, no estilo do Anki (spec 009).
class CreateFlashcardsModule < ActiveRecord::Migration[8.0]
  def change
    create_table :flashcards_decks do |t|
      t.string :name, null: false
      t.text :description
      t.integer :new_per_day, null: false, default: 20
      t.integer :reviews_per_day, null: false, default: 200
      t.timestamps
      t.check_constraint "new_per_day BETWEEN 0 AND 9999", name: "flashcards_decks_new_per_day_range"
      t.check_constraint "reviews_per_day BETWEEN 0 AND 9999", name: "flashcards_decks_reviews_per_day_range"
    end
    add_index :flashcards_decks, "lower(name)", unique: true, name: "index_flashcards_decks_on_lower_name"

    create_table :flashcards_notes do |t|
      t.references :deck, null: false, foreign_key: { to_table: :flashcards_decks, on_delete: :cascade }
      t.string :note_type, null: false, default: "basic"
      t.text :front, null: false
      t.text :back, null: false
      t.string :tags, array: true, null: false, default: []
      t.boolean :suspended, null: false, default: false
      t.virtual :tags_text, type: :text, stored: true, as: "immutable_array_to_string(tags::text[], ' ')"
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(front, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(back, '')), 'B')
      SQL
      t.timestamps
      t.check_constraint "note_type IN ('basic', 'basic_reversed')", name: "flashcards_notes_note_type_valid"
    end
    add_index :flashcards_notes, :searchable, using: :gin

    create_table :flashcards_cards do |t|
      t.references :note, null: false, index: false, foreign_key: { to_table: :flashcards_notes, on_delete: :cascade }
      t.integer :ordinal, null: false, default: 0
      t.string :state, null: false, default: "new"
      t.datetime :due_at
      t.integer :interval_days, null: false, default: 0
      t.integer :ease, null: false, default: 2500
      t.integer :step_index, null: false, default: 0
      t.integer :reps, null: false, default: 0
      t.integer :lapses, null: false, default: 0
      t.datetime :last_reviewed_at
      t.timestamps
      t.check_constraint "state IN ('new', 'learning', 'review', 'relearning')", name: "flashcards_cards_state_valid"
      t.check_constraint "ordinal IN (0, 1)", name: "flashcards_cards_ordinal_valid"
    end
    add_index :flashcards_cards, %i[note_id ordinal], unique: true
    add_index :flashcards_cards, %i[state due_at]

    create_table :flashcards_reviews do |t|
      t.references :card, null: false, index: false, foreign_key: { to_table: :flashcards_cards, on_delete: :cascade }
      t.integer :rating, null: false
      t.string :state_before, null: false
      t.integer :interval_before, null: false, default: 0
      t.integer :interval_after, null: false, default: 0
      t.integer :ease_after, null: false
      t.integer :duration_ms
      t.datetime :reviewed_at, null: false
      t.datetime :created_at, null: false
      t.check_constraint "rating BETWEEN 1 AND 4", name: "flashcards_reviews_rating_range"
    end
    add_index :flashcards_reviews, %i[card_id reviewed_at]
    add_index :flashcards_reviews, :reviewed_at
  end
end
