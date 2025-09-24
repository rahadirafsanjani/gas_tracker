# Development Guide

This guide provides detailed instructions for developers working on the Cross-Chain Gas Tracker application.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Code Style and Standards](#code-style-and-standards)
- [Testing Strategy](#testing-strategy)
- [Database Development](#database-development)
- [API Development](#api-development)
- [Frontend Development](#frontend-development)
- [Background Jobs](#background-jobs)
- [Debugging and Troubleshooting](#debugging-and-troubleshooting)
- [Performance Optimization](#performance-optimization)
- [Contributing Guidelines](#contributing-guidelines)

## Development Environment Setup

### Prerequisites

```bash
# Check versions
ruby --version    # Should be 3.4.3
rails --version   # Should be 8.0.2.1
docker --version  # Should be 20.10+
node --version    # Should be 18+
```

### Initial Setup

```bash
# Clone and setup
git clone https://github.com/your-username/gas-tracker.git
cd gas-tracker
bundle install
gem install foreman

# Environment setup
cp .env.example .env
docker compose up -d

# Database setup
rails db:create db:migrate
rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"
rails db:seed

# Start development
bin/dev
```

## Code Style and Standards

### Ruby Style Guide

```ruby
# Use double quotes for strings
message = "Hello, world!"

# Use trailing commas in multi-line arrays/hashes
chains = [
  "Ethereum",
  "Polygon",
  "Arbitrum",
]

# Prefer explicit returns
def calculate_average(values)
  return 0 if values.empty?
  
  values.sum / values.size
end
```

### RuboCop Configuration

```yaml
# .rubocop.yml
require:
  - rubocop-rails
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.4
  NewCops: enable

Style/StringLiterals:
  EnforcedStyle: double_quotes

Layout/LineLength:
  Max: 120

Metrics/MethodLength:
  Max: 20
```

### Running Code Quality Checks

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a

# Run security scanner
bundle exec brakeman

# Run tests
rails test
```

## Testing Strategy

### Model Testing

```ruby
# test/models/chain_test.rb
require "test_helper"

class ChainTest < ActiveSupport::TestCase
  def setup
    @chain = chains(:ethereum)
  end

  test "should be valid with valid attributes" do
    assert @chain.valid?
  end

  test "should require name" do
    @chain.name = nil
    assert_not @chain.valid?
    assert_includes @chain.errors[:name], "can't be blank"
  end

  test "latest_gas_reading returns most recent reading" do
    old_reading = gas_readings(:ethereum_old)
    recent_reading = gas_readings(:ethereum_recent)
    
    assert_equal recent_reading, @chain.latest_gas_reading
  end
end
```

### Service Testing

```ruby
# test/services/gas_price_fetcher_test.rb
require "test_helper"

class GasPriceFetcherTest < ActiveSupport::TestCase
  def setup
    @chain = chains(:ethereum)
    @fetcher = GasPriceFetcher.new(@chain)
  end

  test "successfully fetches gas price for valid chain" do
    stub_successful_rpc_response
    
    result = @fetcher.call
    
    assert result.success?
    assert_instance_of GasReading, result.data
  end

  private

  def stub_successful_rpc_response
    stub_request(:post, @chain.rpc_url)
      .to_return(
        status: 200,
        body: { jsonrpc: "2.0", result: "0x5d21dba00", id: 1 }.to_json
      )
  end
end
```

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/chain_test.rb

# Run with coverage
COVERAGE=true rails test
```

## Database Development

### Migration Best Practices

```ruby
# Good migration example
class AddIndexToGasReadingsTimestamp < ActiveRecord::Migration[8.0]
  disable_ddl_transaction! # For concurrent index creation
  
  def change
    add_index :gas_readings, :timestamp, algorithm: :concurrently
  end
end
```

### Useful Database Queries

```ruby
# In Rails console

# Check gas reading distribution by chain
GasReading.joins(:chain).group('chains.name').count

# Find chains with stale data
Chain.joins(:gas_readings)
  .where('gas_readings.timestamp < ?', 1.hour.ago)
  .distinct

# Calculate average gas prices by hour
GasReading.where('timestamp > ?', 24.hours.ago)
  .group("DATE_TRUNC('hour', timestamp)")
  .average(:gas_price_gwei)
```

## API Development

### Creating New API Endpoints

```ruby
# 1. Add route
namespace :api do
  namespace :v1 do
    resources :analytics, only: [:index]
  end
end

# 2. Create controller
class Api::V1::AnalyticsController < Api::V1::BaseController
  def index
    analytics_data = AnalyticsService.call(analytics_params)
    
    if analytics_data.success?
      render_success(analytics_data.data)
    else
      render_error(analytics_data.error)
    end
  end

  private

  def analytics_params
    params.permit(:period, :chain_ids, :metric)
  end
end
```

## Frontend Development

### Stimulus Controller Development

```javascript
// app/javascript/controllers/gas_price_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static targets = ["canvas"]
  static values = { chainId: Number }

  connect() {
    this.initializeChart()
    this.loadData()
  }

  async loadData() {
    try {
      const response = await fetch(`/api/v1/gas_prices/${this.chainIdValue}`)
      const data = await response.json()
      this.updateChart(data.data.historical_data)
    } catch (error) {
      console.error('Failed to load chart data:', error)
    }
  }
}
```

### Tailwind CSS Customization

```css
/* app/assets/stylesheets/application.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .card {
    @apply bg-white rounded-lg shadow-md p-6;
  }
  
  .btn-primary {
    @apply bg-blue-600 text-white hover:bg-blue-700 px-4 py-2 rounded-md;
  }
  
  .gas-price-display {
    @apply text-2xl font-bold;
  }
}
```

## Background Jobs

### Job Development Best Practices

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  include SolidQueue::Job
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
  
  around_perform :with_job_instrumentation
  
  private
  
  def with_job_instrumentation
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

### Job Monitoring

```ruby
# Check job queue status
SolidQueue::Job.where(finished_at: nil).count

# View recent jobs
SolidQueue::Job.order(created_at: :desc).limit(10)

# Check failed jobs
SolidQueue::FailedExecution.includes(:job).each do |failure|
  puts "#{failure.job.class_name}: #{failure.error}"
end
```

## Debugging and Troubleshooting

### Common Debugging Commands

```bash
# Debug database queries
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Test RPC endpoints
curl -X POST https://eth.llamarpc.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}'

# Check Docker services
docker compose ps
docker compose logs postgres
docker compose logs redis
```

### Performance Debugging

```ruby
# Benchmark code execution
require 'benchmark'

time = Benchmark.measure do
  GasPriceFetcher.new.fetch_all_chains
end

puts "Execution time: #{time.real} seconds"

# Profile memory usage
require 'memory_profiler'

report = MemoryProfiler.report do
  UpdateGasPricesJob.perform_now
end

report.pretty_print
```

## Performance Optimization

### Database Optimization

```ruby
# Use includes to avoid N+1 queries
@chains = Chain.active.includes(:gas_readings)

# Use select to limit columns
Chain.select(:id, :name, :chain_id).active

# Use find_each for large datasets
Chain.find_each(batch_size: 100) do |chain|
  # Process chain
end
```

### Caching Strategies

```ruby
# Fragment caching in views
<% cache @chain do %>
  <%= render @chain %>
<% end %>

# Low-level caching
Rails.cache.fetch("chain_#{chain.id}_latest_reading", expires_in: 1.minute) do
  chain.latest_gas_reading
end
```

## Contributing Guidelines

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-analytics-endpoint

# Make changes and commit
git add .
git commit -m "feat: add analytics endpoint for gas price trends"

# Push and create PR
git push origin feature/new-analytics-endpoint
```

### Commit Message Format

```
feat: add new blockchain network support
fix: resolve gas price calculation issue
docs: update API documentation
test: add integration tests for dashboard
refactor: improve gas price fetcher service
```

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No security vulnerabilities
- [ ] Performance impact considered
- [ ] Database migrations are safe

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
```

This development guide provides essential information for contributing to the Gas Tracker project effectively.
