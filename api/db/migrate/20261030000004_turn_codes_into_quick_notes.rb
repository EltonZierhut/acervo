# Códigos vira bloco de notas: sem projetos e com título opcional (feature 003).
# Os projetos e os vínculos apagados aqui não voltam no down; as notas são preservadas.
class TurnCodesIntoQuickNotes < ActiveRecord::Migration[8.0]
  def up
    remove_reference :codes_snippets, :project, foreign_key: { to_table: :codes_projects }
    drop_table :codes_projects

    change_column_null :codes_snippets, :title, true
    # Permite buscar por pedaços de tags com o ILIKE do Searchable.
    add_column :codes_snippets, :tags_text, :virtual, type: :text, stored: true,
      as: "immutable_array_to_string(tags::text[], ' ')"
  end

  def down
    remove_column :codes_snippets, :tags_text

    execute <<~SQL
      UPDATE codes_snippets
      SET title = left(coalesce(
        substring(content from '(?n)^[[:space:]]*([^[:space:]].*)$'), 'Sem título'), 200)
      WHERE title IS NULL
    SQL
    change_column_null :codes_snippets, :title, false

    create_table :codes_projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :repository_url
      t.string :tags, array: true, null: false, default: []
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(description, '')), 'B')
      SQL
      t.timestamps
    end
    add_index :codes_projects, :name, unique: true
    add_index :codes_projects, :searchable, using: :gin

    add_reference :codes_snippets, :project, foreign_key: { to_table: :codes_projects, on_delete: :nullify }
  end
end
