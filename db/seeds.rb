# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial chain data
chains_data = [
  {
    name: 'Ethereum',
    chain_id: 1,
    rpc_url: ENV.fetch('ETHEREUM_RPC', 'https://eth.llamarpc.com'),
    native_token: 'ETH',
    is_active: true
  },
  {
    name: 'Polygon',
    chain_id: 137,
    rpc_url: ENV.fetch('POLYGON_RPC', 'https://polygon-rpc.com'),
    native_token: 'MATIC',
    is_active: true
  },
  {
    name: 'Arbitrum',
    chain_id: 42161,
    rpc_url: ENV.fetch('ARBITRUM_RPC', 'https://arb1.arbitrum.io/rpc'),
    native_token: 'ETH',
    is_active: true
  },
  {
    name: 'Optimism',
    chain_id: 10,
    rpc_url: ENV.fetch('OPTIMISM_RPC', 'https://mainnet.optimism.io'),
    native_token: 'ETH',
    is_active: true
  },
  {
    name: 'BNB Chain',
    chain_id: 56,
    rpc_url: 'https://bsc-dataseed1.binance.org',
    native_token: 'BNB',
    is_active: true
  },
  {
    name: 'Avalanche',
    chain_id: 43114,
    rpc_url: 'https://api.avax.network/ext/bc/C/rpc',
    native_token: 'AVAX',
    is_active: true
  }
]

chains_data.each do |chain_data|
  Chain.find_or_create_by!(chain_id: chain_data[:chain_id]) do |chain|
    chain.name = chain_data[:name]
    chain.rpc_url = chain_data[:rpc_url]
    chain.native_token = chain_data[:native_token]
    chain.is_active = chain_data[:is_active]
  end
end

puts "Created #{Chain.count} chains"
