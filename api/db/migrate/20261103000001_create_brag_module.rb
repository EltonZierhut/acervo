# Módulo Brag document: registro de conquistas para lembrar na avaliação (feature brag).
class CreateBragModule < ActiveRecord::Migration[8.0]
  def change
    create_table :brag_entries do |t|
      t.string :title, null: false
      t.date :achieved_on, null: false
      t.text :description
      t.string :category
      t.string :tags, array: true, null: false, default: []
      t.text :impact
      t.text :metrics
      t.string :evidence_links, array: true, null: false, default: []
      t.string :project
      t.virtual :tags_text, type: :text, stored: true, as: "immutable_array_to_string(tags::text[], ' ')"
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(category, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(project, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(description, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(impact, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(metrics, '')), 'C')
      SQL
      t.timestamps
    end
    add_index :brag_entries, :achieved_on
    add_index :brag_entries, :searchable, using: :gin
  end
end
