class BridgeRoute < ApplicationRecord
  belongs_to :source_chain, class_name: 'Chain'
  belongs_to :destination_chain, class_name: 'Chain'
  
  validates :fee_usd, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :protocol, presence: true
  validate :different_chains
  
  scope :for_route, ->(source, destination) { where(source_chain: source, destination_chain: destination) }
  
  private
  
  def different_chains
    if source_chain_id == destination_chain_id
      errors.add(:destination_chain, "must be different from source chain")
    end
  end
end
