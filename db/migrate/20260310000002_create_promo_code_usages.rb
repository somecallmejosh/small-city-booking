class CreatePromoCodeUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_code_usages do |t|
      t.references :promo_code, null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true
      t.references :booking,    null: false, foreign_key: true

      t.timestamps
    end

    add_index :promo_code_usages, [ :promo_code_id, :user_id ], unique: true
  end
end
