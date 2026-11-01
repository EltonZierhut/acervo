class AddRepositoryToInitiatives < ActiveRecord::Migration[8.0]
  def change
    change_table :initiatives_initiatives, bulk: true do |t|
      t.string :github_repository
      t.string :repository_status, null: false, default: "unverified"
      t.text :repository_error
      t.datetime :repository_checked_at
      t.check_constraint "repository_status IN ('unverified', 'valid', 'invalid')",
        name: "initiatives_initiatives_repository_status_check"
    end

    create_table :initiatives_executors do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.datetime :last_seen_at
      t.string :version
      t.timestamps
    end
  end
end
