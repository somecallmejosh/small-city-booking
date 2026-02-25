class CreateAgreements < ActiveRecord::Migration[8.1]
  def change
    create_table :agreements do |t|
      t.integer :version, null: false
      t.datetime :published_at

      t.datetime :created_at, null: false
    end

    add_index :agreements, :published_at
  end
end
