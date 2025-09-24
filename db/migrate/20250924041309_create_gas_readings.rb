class CreateGasReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :gas_readings do |t|
      t.references :chain, null: false, foreign_key: true
      t.decimal :gas_price_gwei, precision: 20, scale: 9, null: false
      t.decimal :usd_cost, precision: 10, scale: 4
      t.datetime :timestamp, null: false

      t.timestamps
    end
    
    add_index :gas_readings, [:chain_id, :timestamp]
    add_index :gas_readings, :timestamp
  end
end
