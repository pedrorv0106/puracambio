class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :bid
      t.integer :ask
      t.integer :currency
      t.decimal :price, :precision => 32, :scale => 16
      t.decimal :volume, :precision => 32, :scale => 16
      t.decimal :origin_volume, :precision => 32, :scale => 16
      t.integer :state
      t.datetime :done_at
      t.string :type, :limit => 8
      t.integer :member_id
      t.timestamps
    end
  end
end
