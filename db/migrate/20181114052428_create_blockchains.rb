class CreateBlockchains < ActiveRecord::Migration
  def change
    create_table :blockchains do |t|
      t.string  :key,                 null: false,                index: { unique: true }
      t.string  :name
      t.integer :height,              null: false
      t.string  :status,              null: false,                index: true
      
      t.timestamps null: false
    end
  end
end