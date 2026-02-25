class CreateAgreementAcceptances < ActiveRecord::Migration[8.1]
  def change
    create_table :agreement_acceptances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :agreement, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.datetime :accepted_at

      t.timestamps
    end
  end
end
