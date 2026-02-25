class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :agreement, null: false, foreign_key: true
      t.string :status, default: "confirmed", null: false
      t.string :stripe_payment_intent_id
      t.string :stripe_payment_link_id
      t.string :stripe_refund_id
      t.integer :total_cents, null: false
      t.text :notes
      t.boolean :admin_created, default: false, null: false
      t.datetime :cancelled_at
      t.text :cancellation_reason
      t.boolean :refunded, default: false, null: false

      t.timestamps
    end

    add_index :bookings, :status
    add_index :bookings, :stripe_payment_intent_id
  end
end
