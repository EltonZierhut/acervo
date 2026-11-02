require "erb"

# Quadro de tarefas (spec 007): número por iniciativa, posição na coluna e descrição em HTML,
# com uma coluna de texto puro (description_text) para a busca.
class AddBoardAndRichTextToInitiativesTasks < ActiveRecord::Migration[8.0]
  def up
    add_column :initiatives_tasks, :number, :integer
    add_column :initiatives_tasks, :position, :integer, null: false, default: 0
    add_column :initiatives_tasks, :description_text, :text

    execute <<~SQL.squish
      UPDATE initiatives_tasks t SET number = r.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY initiative_id ORDER BY id) AS rn FROM initiatives_tasks) r
      WHERE r.id = t.id
    SQL
    # Mantém a ordem que a lista tinha: prazo nas abertas, conclusão mais recente nas concluídas.
    execute <<~SQL.squish
      UPDATE initiatives_tasks t SET position = r.rn
      FROM (
        SELECT id, row_number() OVER (
          PARTITION BY initiative_id, status
          ORDER BY CASE WHEN status = 'done' THEN NULL ELSE due_on END ASC NULLS LAST,
                   completed_at DESC NULLS LAST, created_at, id
        ) - 1 AS rn
        FROM initiatives_tasks
      ) r
      WHERE r.id = t.id
    SQL

    # Descrições antigas são texto puro: viram parágrafos.
    select_rows("SELECT id, description FROM initiatives_tasks WHERE description IS NOT NULL").each do |id, text|
      html = text.strip.split(/(?:\r?\n){2,}/).map { |block|
        "<p>#{ERB::Util.html_escape(block.strip).gsub(/\r?\n/, '<br>')}</p>"
      }.join
      execute "UPDATE initiatives_tasks SET description = #{quote(html)}, description_text = #{quote(text)} WHERE id = #{id.to_i}"
    end

    add_index :initiatives_tasks, %i[initiative_id number], unique: true
    add_index :initiatives_tasks, %i[initiative_id status position], name: "index_initiatives_tasks_on_board_order"
    remove_index :initiatives_tasks, :searchable
    remove_column :initiatives_tasks, :searchable
    add_search_column
    add_index :initiatives_tasks, :searchable, using: :gin
  end

  def down
    remove_index :initiatives_tasks, :searchable
    remove_column :initiatives_tasks, :searchable
    execute "UPDATE initiatives_tasks SET description = description_text"
    remove_index :initiatives_tasks, name: "index_initiatives_tasks_on_board_order"
    remove_index :initiatives_tasks, %i[initiative_id number]
    remove_column :initiatives_tasks, :description_text
    remove_column :initiatives_tasks, :position
    remove_column :initiatives_tasks, :number
    add_search_column(:description)
    add_index :initiatives_tasks, :searchable, using: :gin
  end

  private

  def add_search_column(description = :description_text)
    add_column :initiatives_tasks, :searchable, :virtual, type: :tsvector, stored: true, as: <<~SQL.squish
      setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
      setweight(to_tsvector('simple', coalesce(#{description}, '')), 'B')
    SQL
  end
end
