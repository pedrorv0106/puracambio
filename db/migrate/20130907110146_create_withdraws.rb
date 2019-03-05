class CreateWithdraws < ActiveRecord::Migration
  def change
    create_table :withdraws do |t|
      t.integer :account_id
      t.decimal :amount, :precision => 32, :scale => 16
      t.integer :payment_way
      t.string :payment_to
      t.integer :state

      t.timestamps
    end
  end
end
