class CreateSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :slots do |t|
      t.datetime :starts_at, null: false
      t.string :status, default: "open", null: false
      t.references :held_by_user, null: true, foreign_key: { to_table: :users }
      t.datetime :held_until

      t.timestamps
    end

    add_index :slots, :starts_at
    add_index :slots, :status
    add_index :slots, :held_until
  end
end
