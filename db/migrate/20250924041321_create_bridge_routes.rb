class CreateBridgeRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :bridge_routes do |t|
      t.references :source_chain, null: false, foreign_key: { to_table: :chains }
      t.references :destination_chain, null: false, foreign_key: { to_table: :chains }
      t.decimal :fee_usd, precision: 10, scale: 4
      t.string :protocol, default: 'stargate'

      t.timestamps
    end
    
    add_index :bridge_routes, [:source_chain_id, :destination_chain_id]
  end
end
