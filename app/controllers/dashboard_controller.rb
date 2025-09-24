class DashboardController < ApplicationController
  def index
    @chains = Chain.active.includes(:gas_readings)
    @latest_readings = {}
    
    @chains.each do |chain|
      @latest_readings[chain.id] = chain.latest_gas_reading
    end
    
    @total_chains = @chains.count
    @last_updated = GasReading.maximum(:timestamp)
  end
end
