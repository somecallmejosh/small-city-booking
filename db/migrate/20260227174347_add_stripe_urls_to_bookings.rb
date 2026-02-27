class AddStripeUrlsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :stripe_receipt_url, :string
    add_column :bookings, :stripe_payment_link_url, :string
  end
end
