class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :phone, :string
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :stripe_customer_id, :string
  end
end
