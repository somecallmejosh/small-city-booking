class CreatePromoCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_codes do |t|
      t.string  :name,             null: false
      t.string  :code,             null: false
      t.integer :discount_percent, null: false
      t.date    :start_date,       null: false
      t.date    :end_date,         null: false
      t.boolean :active,           null: false, default: true

      t.timestamps
    end

    add_index :promo_codes, :code, unique: true
  end
end
