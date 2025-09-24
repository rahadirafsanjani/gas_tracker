class UpdateGasPricesJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform
    Rails.logger.info "Starting gas price update job"
    
    fetcher = GasPriceFetcher.new
    fetcher.fetch_all_chains
    
    Rails.logger.info "Completed gas price update job"
    
    # Schedule the next job
    UpdateGasPricesJob.set(wait: 60.seconds).perform_later
  end
end
