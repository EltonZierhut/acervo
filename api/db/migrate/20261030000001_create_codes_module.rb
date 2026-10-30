# Módulo Códigos: projetos e trechos de código, com busca full-text.
class CreateCodesModule < ActiveRecord::Migration[8.0]
  def up
    enable_extension "pg_trgm"

    # array_to_string não é IMMUTABLE, e colunas geradas exigem isso.
    execute <<~SQL
      CREATE OR REPLACE FUNCTION immutable_array_to_string(text[], text)
      RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
      AS $$ SELECT array_to_string($1, $2) $$;
    SQL

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

    create_table :codes_snippets do |t|
      t.references :project, foreign_key: { to_table: :codes_projects, on_delete: :nullify }
      t.string :title, null: false
      t.text :description
      t.string :language
      t.text :content, null: false
      t.string :tags, array: true, null: false, default: []
      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', immutable_array_to_string(tags::text[], ' ')), 'A') ||
        setweight(to_tsvector('simple', coalesce(language, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(description, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(content, '')), 'C')
      SQL
      t.timestamps
    end
    add_index :codes_snippets, :searchable, using: :gin
    add_index :codes_snippets, :tags, using: :gin
    # Busca por pedaços de identificadores (ex.: "useDeb") dentro do código.
    add_index :codes_snippets, :content, using: :gin, opclass: :gin_trgm_ops
    add_index :codes_snippets, :title, using: :gin, opclass: :gin_trgm_ops
  end

  def down
    drop_table :codes_snippets
    drop_table :codes_projects
    execute "DROP FUNCTION IF EXISTS immutable_array_to_string(text[], text)"
  end
end
