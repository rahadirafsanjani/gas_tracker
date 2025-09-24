class CreateChains < ActiveRecord::Migration[8.0]
  def change
    create_table :chains do |t|
      t.string :name, null: false
      t.integer :chain_id, null: false
      t.string :rpc_url, null: false
      t.string :native_token, null: false, default: 'ETH'
      t.boolean :is_active, default: true

      t.timestamps
    end
    
    add_index :chains, :chain_id, unique: true
  end
end
