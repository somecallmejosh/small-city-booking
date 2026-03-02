class AddEmailVerifiedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verified_at, :datetime
    # Backfill existing users — they were created by admin before self-registration existed
    User.where(admin: false).in_batches.update_all(email_verified_at: Time.current)
  end
end
