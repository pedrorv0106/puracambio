class CreateDeposits < ActiveRecord::Migration
  def change
    create_table :deposits do |t|
      t.integer :account_id
      t.decimal :amount, :precision => 32, :scale => 16
      t.integer :payment_way
      t.string :payment_id
      t.integer :state

      t.timestamps
    end
  end
end
