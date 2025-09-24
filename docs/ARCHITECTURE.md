# Architecture Documentation

This document provides a comprehensive overview of the Cross-Chain Gas Tracker application architecture, design patterns, and technical decisions.

## Table of Contents

- [System Overview](#system-overview)
- [Application Architecture](#application-architecture)
- [Database Design](#database-design)
- [Service Layer](#service-layer)
- [Background Jobs](#background-jobs)
- [Frontend Architecture](#frontend-architecture)
- [API Design](#api-design)
- [Security Architecture](#security-architecture)
- [Performance Considerations](#performance-considerations)
- [Scalability Design](#scalability-design)

## System Overview

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │   Mobile App    │    │  Third-party    │
│                 │    │                 │    │  Integrations   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Load Balancer        │
                    │      (Nginx/HAProxy)      │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │     Rails Application     │
                    │      (Web Servers)        │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
│   PostgreSQL      │  │      Redis        │  │  Background Jobs  │
│   (Primary DB)    │  │   (Cache/Queue)   │  │  (Solid Queue)    │
└───────────────────┘  └───────────────────┘  └───────────────────┘
          │                      │                      │
          │                      │                      │
┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
│   Read Replicas   │  │   Redis Cluster   │  │   External APIs   │
│   (Scaling)       │  │   (HA Setup)      │  │   (RPC Endpoints) │
└───────────────────┘  └───────────────────┘  └───────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Backend Framework** | Rails 8.0.2.1 | Web application framework |
| **Language** | Ruby 3.4.3 | Programming language |
| **Database** | PostgreSQL 16+ | Primary data storage |
| **Cache/Queue** | Redis 7+ | Caching and job queue |
| **Job Processing** | Solid Queue | Background job processing |
| **Frontend** | Tailwind CSS + Stimulus | UI styling and interactions |
| **Asset Pipeline** | Propshaft | Asset management |
| **HTTP Client** | HTTParty | External API communication |
| **Containerization** | Docker Compose | Development environment |

## Application Architecture

### MVC Pattern Implementation

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                   │
├─────────────────────────────────────────────────────────────┤
│  Controllers                │  Views                        │
│  ├── DashboardController    │  ├── dashboard/               │
│  ├── API::V1::*Controllers  │  ├── layouts/                 │
│  └── ApplicationController  │  └── shared/                  │
├─────────────────────────────────────────────────────────────┤
│                        Business Logic Layer                 │
├─────────────────────────────────────────────────────────────┤
│  Services                   │  Jobs                         │
│  ├── GasPriceFetcher       │  ├── UpdateGasPricesJob       │
│  ├── BridgeFeeCalculator   │  ├── CleanupOldDataJob        │
│  └── RecommendationEngine  │  └── NotificationJob          │
├─────────────────────────────────────────────────────────────┤
│                        Data Access Layer                    │
├─────────────────────────────────────────────────────────────┤
│  Models                     │  Database                     │
│  ├── Chain                 │  ├── chains                   │
│  ├── GasReading            │  ├── gas_readings             │
│  ├── BridgeRoute           │  ├── bridge_routes            │
│  └── ApplicationRecord     │  └── solid_queue_*            │
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── dashboard_controller.rb
│   └── api/
│       └── v1/
│           ├── base_controller.rb
│           ├── chains_controller.rb
│           └── gas_prices_controller.rb
├── models/
│   ├── application_record.rb
│   ├── chain.rb
│   ├── gas_reading.rb
│   └── bridge_route.rb
├── services/
│   ├── gas_price_fetcher.rb
│   ├── bridge_fee_calculator.rb
│   └── recommendation_engine.rb
├── jobs/
│   ├── application_job.rb
│   ├── update_gas_prices_job.rb
│   └── cleanup_old_data_job.rb
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── dashboard/
│   │   └── index.html.erb
│   └── shared/
│       ├── _header.html.erb
│       └── _footer.html.erb
├── helpers/
│   ├── application_helper.rb
│   └── dashboard_helper.rb
└── assets/
    ├── stylesheets/
    │   └── application.css
    └── javascript/
        ├── application.js
        └── controllers/
```

## Database Design

### Entity Relationship Diagram

```
┌─────────────────┐         ┌─────────────────┐
│     chains      │         │  gas_readings   │
├─────────────────┤         ├─────────────────┤
│ id (PK)         │◄────────┤ id (PK)         │
│ name            │    1:N  │ chain_id (FK)   │
│ chain_id (UQ)   │         │ gas_price_gwei  │
│ rpc_url         │         │ usd_cost        │
│ native_token    │         │ timestamp       │
│ is_active       │         │ created_at      │
│ created_at      │         │ updated_at      │
│ updated_at      │         └─────────────────┘
└─────────────────┘                 │
         │                          │
         │                          │
         │         ┌─────────────────▼─────────────────┐
         │         │           Indexes                 │
         │         ├─────────────────────────────────────┤
         │         │ idx_gas_readings_chain_timestamp   │
         │         │ idx_gas_readings_timestamp         │
         │         └─────────────────────────────────────┘
         │
         │
┌────────▼─────────┐         ┌─────────────────┐
│ bridge_routes    │         │ bridge_routes   │
├──────────────────┤         ├─────────────────┤
│ id (PK)          │         │ id (PK)         │
│ source_chain_id  │◄────────┤ source_chain_id │
│ dest_chain_id    │    N:1  │ dest_chain_id   │
│ fee_usd          │         │ fee_usd         │
│ protocol         │         │ protocol        │
│ created_at       │         │ created_at      │
│ updated_at       │         │ updated_at      │
└──────────────────┘         └─────────────────┘
```

### Database Schema Details

#### Chains Table

```sql
CREATE TABLE chains (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  chain_id INTEGER UNIQUE NOT NULL,
  rpc_url VARCHAR NOT NULL,
  native_token VARCHAR NOT NULL DEFAULT 'ETH',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX idx_chains_chain_id ON chains (chain_id);
CREATE INDEX idx_chains_active ON chains (is_active) WHERE is_active = true;
```

#### Gas Readings Table

```sql
CREATE TABLE gas_readings (
  id BIGSERIAL PRIMARY KEY,
  chain_id BIGINT NOT NULL REFERENCES chains(id) ON DELETE CASCADE,
  gas_price_gwei DECIMAL(20,9) NOT NULL,
  usd_cost DECIMAL(10,4),
  timestamp TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_gas_readings_chain_timestamp ON gas_readings (chain_id, timestamp DESC);
CREATE INDEX idx_gas_readings_timestamp ON gas_readings (timestamp DESC);
CREATE INDEX idx_gas_readings_chain_latest ON gas_readings (chain_id, timestamp DESC) 
  WHERE timestamp > NOW() - INTERVAL '1 hour';
```

#### Bridge Routes Table

```sql
CREATE TABLE bridge_routes (
  id BIGSERIAL PRIMARY KEY,
  source_chain_id BIGINT NOT NULL REFERENCES chains(id) ON DELETE CASCADE,
  destination_chain_id BIGINT NOT NULL REFERENCES chains(id) ON DELETE CASCADE,
  fee_usd DECIMAL(10,4),
  protocol VARCHAR DEFAULT 'stargate',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  CONSTRAINT different_chains CHECK (source_chain_id != destination_chain_id)
);

-- Indexes
CREATE INDEX idx_bridge_routes_source_dest ON bridge_routes (source_chain_id, destination_chain_id);
CREATE INDEX idx_bridge_routes_protocol ON bridge_routes (protocol);
```

### Data Retention Strategy

```sql
-- Partition gas_readings by month for better performance
CREATE TABLE gas_readings_y2025m01 PARTITION OF gas_readings
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Automatic cleanup of old data
CREATE OR REPLACE FUNCTION cleanup_old_gas_readings()
RETURNS void AS $$
BEGIN
  DELETE FROM gas_readings 
  WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (via cron job or Rails job)
SELECT cron.schedule('cleanup-gas-readings', '0 2 * * *', 'SELECT cleanup_old_gas_readings();');
```

## Service Layer

### Service Object Pattern

```ruby
# Base service class
class ApplicationService
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  def call
    raise NotImplementedError
  end

  private

  def success(data = nil)
    ServiceResult.new(success: true, data: data)
  end

  def failure(error)
    ServiceResult.new(success: false, error: error)
  end
end

# Service result object
class ServiceResult
  attr_reader :data, :error

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
```

### Gas Price Fetcher Service

```ruby
class GasPriceFetcher < ApplicationService
  include HTTParty
  
  TIMEOUT = 10.seconds
  RETRY_ATTEMPTS = 3
  
  def initialize(chain = nil)
    @chain = chain
    self.class.default_timeout(TIMEOUT)
  end

  def call
    if @chain
      fetch_single_chain(@chain)
    else
      fetch_all_chains
    end
  end

  private

  def fetch_all_chains
    results = []
    
    Chain.active.find_each do |chain|
      result = fetch_single_chain(chain)
      results << result if result.success?
    end
    
    success(results)
  rescue => e
    failure("Failed to fetch gas prices: #{e.message}")
  end

  def fetch_single_chain(chain)
    retries = 0
    
    begin
      gas_price_wei = fetch_from_rpc(chain.rpc_url)
      gas_price_gwei = wei_to_gwei(gas_price_wei)
      usd_cost = calculate_usd_cost(gas_price_gwei, chain.native_token)
      
      reading = create_gas_reading(chain, gas_price_gwei, usd_cost)
      success(reading)
      
    rescue => e
      retries += 1
      if retries <= RETRY_ATTEMPTS
        sleep(2 ** retries) # Exponential backoff
        retry
      else
        failure("Failed to fetch gas price for #{chain.name}: #{e.message}")
      end
    end
  end

  def fetch_from_rpc(rpc_url)
    response = self.class.post(rpc_url, {
      body: rpc_request_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    })
    
    handle_rpc_response(response)
  end

  def rpc_request_body
    {
      jsonrpc: "2.0",
      method: "eth_gasPrice",
      params: [],
      id: SecureRandom.uuid
    }
  end

  def handle_rpc_response(response)
    raise "HTTP Error: #{response.code}" unless response.success?
    
    result = response.parsed_response
    raise "RPC Error: #{result['error']['message']}" if result['error']
    
    result['result'].to_i(16)
  end

  def wei_to_gwei(wei)
    wei.to_f / 1_000_000_000
  end

  def calculate_usd_cost(gas_price_gwei, native_token)
    # Implementation for USD cost calculation
    # This would integrate with CoinGecko API
    nil
  end

  def create_gas_reading(chain, gas_price_gwei, usd_cost)
    chain.gas_readings.create!(
      gas_price_gwei: gas_price_gwei,
      usd_cost: usd_cost,
      timestamp: Time.current
    )
  end
end
```

## Background Jobs

### Job Architecture

```ruby
# Base job class with common functionality
class ApplicationJob < ActiveJob::Base
  include Solid::Job
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
  
  around_perform :with_job_logging
  
  private
  
  def with_job_logging
    Rails.logger.info "Starting job: #{self.class.name}"
    start_time = Time.current
    
    yield
    
    duration = Time.current - start_time
    Rails.logger.info "Completed job: #{self.class.name} in #{duration.round(2)}s"
  rescue => e
    Rails.logger.error "Job failed: #{self.class.name} - #{e.message}"
    raise
  end
end
```

### Update Gas Prices Job

```ruby
class UpdateGasPricesJob < ApplicationJob
  queue_as :default
  
  def perform
    result = GasPriceFetcher.call
    
    if result.success?
      schedule_next_update
      notify_if_significant_changes(result.data)
    else
      Rails.logger.error "Gas price update failed: #{result.error}"
      # Could trigger alert here
    end
  end

  private

  def schedule_next_update
    UpdateGasPricesJob.set(wait: 60.seconds).perform_later
  end

  def notify_if_significant_changes(readings)
    readings.each do |reading|
      chain = reading.chain
      previous_reading = chain.gas_readings
                             .where('timestamp < ?', reading.timestamp)
                             .order(timestamp: :desc)
                             .first
      
      if previous_reading && significant_change?(reading, previous_reading)
        GasPriceAlertJob.perform_later(reading, previous_reading)
      end
    end
  end

  def significant_change?(current, previous)
    change_percentage = ((current.gas_price_gwei - previous.gas_price_gwei) / previous.gas_price_gwei * 100).abs
    change_percentage > 20 # Alert if >20% change
  end
end
```

### Job Queue Configuration

```ruby
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: default
      threads: 3
      processes: 2
    - queues: critical
      threads: 1
      processes: 1
      priority: 10
```

## Frontend Architecture

### Stimulus Controllers

```javascript
// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gasPrice", "lastUpdated", "status"]
  static values = { 
    refreshInterval: Number,
    autoRefresh: Boolean 
  }

  connect() {
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    }
  }

  disconnect() {
    this.stopAutoRefresh()
  }

  refresh() {
    this.updateStatus("loading")
    
    fetch("/api/v1/gas_prices", {
      headers: { "Accept": "application/json" }
    })
    .then(response => response.json())
    .then(data => this.updateGasPrices(data))
    .catch(error => this.handleError(error))
  }

  updateGasPrices(data) {
    data.data.forEach(item => {
      const element = this.gasPriceTargets.find(
        el => el.dataset.chainId === item.chain.id.toString()
      )
      
      if (element) {
        element.textContent = `${item.gas_reading.gas_price_gwei} gwei`
        this.updatePriceStatus(element, item.gas_reading.status)
      }
    })
    
    this.updateLastUpdated()
    this.updateStatus("success")
  }

  updatePriceStatus(element, status) {
    element.className = `gas-price ${status}`
  }

  updateLastUpdated() {
    if (this.hasLastUpdatedTarget) {
      this.lastUpdatedTarget.textContent = new Date().toLocaleTimeString()
    }
  }

  updateStatus(status) {
    if (this.hasStatusTarget) {
      this.statusTarget.className = `status ${status}`
    }
  }

  handleError(error) {
    console.error("Failed to update gas prices:", error)
    this.updateStatus("error")
  }

  startAutoRefresh() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.refreshIntervalValue * 1000)
  }

  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}
```

### CSS Architecture (Tailwind)

```css
/* app/assets/stylesheets/application.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom components */
@layer components {
  .gas-price {
    @apply text-lg font-medium transition-colors duration-200;
  }
  
  .gas-price.active {
    @apply text-green-600;
  }
  
  .gas-price.stale {
    @apply text-yellow-600;
  }
  
  .gas-price.error {
    @apply text-red-600;
  }
  
  .status-indicator {
    @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  
  .status-indicator.active {
    @apply bg-green-100 text-green-800;
  }
  
  .status-indicator.stale {
    @apply bg-yellow-100 text-yellow-800;
  }
  
  .status-indicator.error {
    @apply bg-red-100 text-red-800;
  }
}
```

## API Design

### RESTful API Structure

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :chains, only: [:index, :show] do
        resources :gas_readings, only: [:index]
      end
      
      resources :gas_prices, only: [:index, :show]
      resources :bridge_routes, only: [:index, :show]
      
      # Health check
      get :health, to: 'health#show'
    end
  end
end
```

### API Base Controller

```ruby
class Api::V1::BaseController < ApplicationController
  include ActionController::API
  
  before_action :set_default_format
  before_action :set_cors_headers
  
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  
  private
  
  def set_default_format
    request.format = :json
  end
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end
  
  def render_success(data, meta = {})
    render json: {
      data: data,
      meta: default_meta.merge(meta)
    }
  end
  
  def render_error(message, code = 'INTERNAL_ERROR', status = :internal_server_error)
    render json: {
      error: {
        code: code,
        message: message
      },
      meta: default_meta
    }, status: status
  end
  
  def default_meta
    {
      timestamp: Time.current.iso8601,
      version: '1.0'
    }
  end
  
  def record_not_found
    render_error('Resource not found', 'RESOURCE_NOT_FOUND', :not_found)
  end
  
  def parameter_missing(exception)
    render_error(exception.message, 'INVALID_PARAMETERS', :bad_request)
  end
end
```

## Security Architecture

### Input Validation

```ruby
# Strong parameters
class DashboardController < ApplicationController
  private
  
  def chain_params
    params.permit(:id, :active, :limit, :offset)
  end
end

# Model validations
class Chain < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100 }
  validates :chain_id, presence: true, uniqueness: true, numericality: { greater_than: 0 }
  validates :rpc_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :native_token, presence: true, length: { maximum: 10 }
end
```

### Rate Limiting

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle API requests
  throttle('api/requests/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end
  
  # Throttle dashboard requests
  throttle('dashboard/requests/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.path == '/'
  end
end
```

### Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
  end
end
```

## Performance Considerations

### Database Optimization

```ruby
# Query optimization
class Chain < ApplicationRecord
  scope :with_latest_reading, -> {
    joins(<<-SQL)
      LEFT JOIN LATERAL (
        SELECT * FROM gas_readings 
        WHERE gas_readings.chain_id = chains.id 
        ORDER BY timestamp DESC 
        LIMIT 1
      ) latest_reading ON true
    SQL
  }
  
  # Efficient average calculation
  def average_gas_price(hours = 24)
    gas_readings
      .where('timestamp > ?', hours.hours.ago)
      .average(:gas_price_gwei)
  end
end
```

### Caching Strategy

```ruby
# Fragment caching
class DashboardController < ApplicationController
  def index
    @chains = Rails.cache.fetch('dashboard_chains', expires_in: 1.minute) do
      Chain.active.with_latest_reading.to_a
    end
  end
end

# Russian doll caching
# In views
<% cache @chain do %>
  <% cache @chain.latest_gas_reading do %>
    <!-- Gas price display -->
  <% end %>
<% end %>
```

### Background Job Optimization

```ruby
# Batch processing
class BatchUpdateGasPricesJob < ApplicationJob
  def perform(chain_ids)
    chains = Chain.where(id: chain_ids)
    
    # Process in parallel using concurrent-ruby
    futures = chains.map do |chain|
      Concurrent::Future.execute do
        GasPriceFetcher.call(chain)
      end
    end
    
    # Wait for all to complete
    futures.each(&:value)
  end
end
```

## Scalability Design

### Horizontal Scaling

```ruby
# Database read replicas
class ApplicationRecord < ActiveRecord::Base
  connects_to database: { 
    writing: :primary, 
    reading: :replica 
  }
end

# Load balancing
class GasPriceFetcher
  def self.distributed_fetch
    chain_groups = Chain.active.in_groups(worker_count)
    
    chain_groups.each_with_index do |chains, index|
      UpdateGasPricesJob
        .set(queue: "worker_#{index}")
        .perform_later(chains.map(&:id))
    end
  end
  
  private
  
  def self.worker_count
    ENV.fetch('WORKER_COUNT', 3).to_i
  end
end
```

### Microservices Preparation

```ruby
# Service boundaries
module GasTracker
  module Services
    class PriceFetcher
      # Isolated service for price fetching
    end
    
    class NotificationService
      # Isolated service for notifications
    end
    
    class AnalyticsService
      # Isolated service for analytics
    end
  end
end
```

This architecture documentation provides a comprehensive overview of the system design, ensuring maintainability, scalability, and performance as the application grows.
