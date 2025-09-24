class GasReading < ApplicationRecord
  belongs_to :chain
  
  validates :gas_price_gwei, presence: true, numericality: { greater_than: 0 }
  validates :timestamp, presence: true
  validates :usd_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :recent, -> { order(timestamp: :desc) }
  scope :for_chain, ->(chain) { where(chain: chain) }
  scope :within_hours, ->(hours) { where('timestamp > ?', hours.hours.ago) }
  
  def self.cleanup_old_data(days_to_keep = 30)
    where('timestamp < ?', days_to_keep.days.ago).delete_all
  end
end
