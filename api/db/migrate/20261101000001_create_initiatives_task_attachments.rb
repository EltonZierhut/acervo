class CreateInitiativesTaskAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :initiatives_task_images do |t|
      t.references :task, null: false, foreign_key: { to_table: :initiatives_tasks, on_delete: :cascade }
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false
      t.integer :position, null: false, default: 0
      t.binary :data, null: false
      t.timestamps
    end

    create_table :initiatives_task_links do |t|
      t.references :task, null: false, foreign_key: { to_table: :initiatives_tasks, on_delete: :cascade }
      t.text :url, null: false
      t.string :title
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
