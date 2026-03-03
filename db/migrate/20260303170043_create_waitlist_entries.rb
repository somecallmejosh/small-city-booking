class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string     :status, null: false, default: "pending"
      t.datetime   :notified_at

      t.timestamps
    end

    add_index :waitlist_entries, :status
  end
end
