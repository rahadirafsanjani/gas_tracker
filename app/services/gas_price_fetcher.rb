class GasPriceFetcher
  include HTTParty
  
  TIMEOUT = 10.seconds
  
  def initialize
    self.class.default_timeout(TIMEOUT)
  end
  
  def fetch_all_chains
    Chain.active.find_each do |chain|
      fetch_gas_price_for_chain(chain)
    end
  end
  
  def fetch_gas_price_for_chain(chain)
    Rails.logger.info "Fetching gas price for #{chain.name}"
    
    begin
      gas_price_wei = fetch_gas_price_from_rpc(chain.rpc_url)
      gas_price_gwei = wei_to_gwei(gas_price_wei)
      usd_cost = calculate_usd_cost(gas_price_gwei, chain.native_token)
      
      gas_reading = chain.gas_readings.create!(
        gas_price_gwei: gas_price_gwei,
        usd_cost: usd_cost,
        timestamp: Time.current
      )
      
      Rails.logger.info "Created gas reading for #{chain.name}: #{gas_price_gwei} gwei"
      gas_reading
    rescue => e
      Rails.logger.error "Failed to fetch gas price for #{chain.name}: #{e.message}"
      nil
    end
  end
  
  private
  
  def fetch_gas_price_from_rpc(rpc_url)
    response = self.class.post(rpc_url, {
      body: {
        jsonrpc: "2.0",
        method: "eth_gasPrice",
        params: [],
        id: 1
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    })
    
    if response.success?
      result = response.parsed_response
      if result['error']
        raise "RPC Error: #{result['error']['message']}"
      end
      
      # Convert hex to integer
      result['result'].to_i(16)
    else
      raise "HTTP Error: #{response.code} - #{response.message}"
    end
  end
  
  def wei_to_gwei(wei)
    wei.to_f / 1_000_000_000
  end
  
  def calculate_usd_cost(gas_price_gwei, native_token)
    # For now, return nil - we'll implement CoinGecko integration later
    # This would calculate the USD cost of a standard transaction (21,000 gas)
    nil
  end
end
