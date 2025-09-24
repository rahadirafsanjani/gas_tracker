class Chain < ApplicationRecord
  has_many :gas_readings, dependent: :destroy
  has_many :source_bridge_routes, class_name: 'BridgeRoute', foreign_key: 'source_chain_id', dependent: :destroy
  has_many :destination_bridge_routes, class_name: 'BridgeRoute', foreign_key: 'destination_chain_id', dependent: :destroy
  
  validates :name, presence: true
  validates :chain_id, presence: true, uniqueness: true
  validates :rpc_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :native_token, presence: true
  
  scope :active, -> { where(is_active: true) }
  
  def latest_gas_reading
    gas_readings.order(timestamp: :desc).first
  end
  
  def average_gas_price(hours_back = 24)
    gas_readings.where('timestamp > ?', hours_back.hours.ago).average(:gas_price_gwei)
  end
end
