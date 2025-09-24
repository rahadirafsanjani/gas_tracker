# Cross-Chain Gas Tracker

A Rails 8 application that tracks gas prices across LayerZero-supported blockchain networks and helps users find the most cost-effective routes for cross-chain transactions.

![Gas Tracker Dashboard](docs/dashboard-screenshot.png)

## 🚀 Features

- **Real-time Gas Price Monitoring**: Track gas prices across 6 major blockchain networks
- **Beautiful Dashboard**: Modern, responsive UI built with Tailwind CSS
- **Background Processing**: Automated gas price updates every 60 seconds using Solid Queue
- **Cross-chain Support**: Ethereum, Polygon, Arbitrum, Optimism, BNB Chain, and Avalanche
- **Historical Data**: Store and analyze gas price trends over time
- **API Ready**: RESTful API endpoints for third-party integrations

## 📋 Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Architecture](#architecture)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)

## 🛠 Requirements

### System Dependencies

- **Ruby**: 3.4.3
- **Rails**: 8.0.2.1
- **PostgreSQL**: 16+
- **Redis**: 7+
- **Docker**: 20.10+ (for development)
- **Docker Compose**: 2.0+

### Development Tools

- **Foreman**: For running multiple processes
- **Tailwind CSS**: For styling
- **Solid Queue**: For background job processing

## 📦 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd gas_tracker
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install Foreman for process management
gem install foreman
```

### 3. Setup Docker Services

```bash
# Start PostgreSQL and Redis containers
docker compose up -d
```

### 4. Database Setup

```bash
# Create and migrate the database
rails db:create
rails db:migrate

# Load Solid Queue schema
rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"

# Seed initial chain data
rails db:seed
```

### 5. Environment Configuration

Copy the environment template and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# Database
DATABASE_URL=postgresql://gas_tracker:password@localhost:5435/gas_tracker_development

# Redis
REDIS_URL=redis://localhost:6380/0

# API Keys (optional)
COINGECKO_API_KEY=your_key_here
LAYERZERO_API_KEY=your_key_here

# Chain RPCs (defaults provided)
ETHEREUM_RPC=https://eth.llamarpc.com
POLYGON_RPC=https://polygon-rpc.com
ARBITRUM_RPC=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC=https://mainnet.optimism.io
```

## 🚀 Usage

### Starting the Application

#### Development Mode (Recommended)

```bash
# Start all services (Rails server + Tailwind CSS compilation)
bin/dev
```

This starts:
- Rails server on `http://localhost:3000`
- Tailwind CSS watcher for real-time style compilation

#### Background Jobs

In a separate terminal, start the job processor:

```bash
# Start Solid Queue worker
bin/jobs
```

#### Manual Gas Price Fetch

To manually trigger gas price updates:

```bash
# Fetch gas prices for all chains
rails runner "UpdateGasPricesJob.perform_now"

# Fetch for a specific chain
rails runner "fetcher = GasPriceFetcher.new; chain = Chain.find_by(name: 'Ethereum'); fetcher.fetch_gas_price_for_chain(chain)"
```

### Accessing the Application

- **Dashboard**: http://localhost:3000
- **Health Check**: http://localhost:3000/up
- **API Base**: http://localhost:3000/api/v1

## 📊 API Documentation

### Endpoints

#### Gas Prices

```bash
# Get all latest gas prices
GET /api/v1/gas_prices

# Get gas prices for a specific chain
GET /api/v1/gas_prices/:chain_id
```

#### Chains

```bash
# Get all supported chains
GET /api/v1/chains

# Get specific chain details
GET /api/v1/chains/:id
```

### Example Response

```json
{
  "chain": {
    "id": 1,
    "name": "Ethereum",
    "chain_id": 1,
    "native_token": "ETH",
    "is_active": true
  },
  "latest_reading": {
    "gas_price_gwei": "25.5",
    "usd_cost": null,
    "timestamp": "2025-09-24T04:38:35.000Z"
  }
}
```

## 🏗 Architecture

### Database Schema

```sql
-- Chains table
chains (
  id: bigint primary key,
  name: varchar not null,
  chain_id: integer unique not null,
  rpc_url: varchar not null,
  native_token: varchar default 'ETH',
  is_active: boolean default true,
  created_at: timestamp,
  updated_at: timestamp
)

-- Gas readings table
gas_readings (
  id: bigint primary key,
  chain_id: bigint references chains(id),
  gas_price_gwei: decimal(20,9) not null,
  usd_cost: decimal(10,4),
  timestamp: timestamp not null,
  created_at: timestamp,
  updated_at: timestamp
)

-- Bridge routes table (for future use)
bridge_routes (
  id: bigint primary key,
  source_chain_id: bigint references chains(id),
  destination_chain_id: bigint references chains(id),
  fee_usd: decimal(10,4),
  protocol: varchar default 'stargate',
  created_at: timestamp,
  updated_at: timestamp
)
```

### Application Structure

```
app/
├── controllers/
│   ├── dashboard_controller.rb      # Main dashboard
│   └── api/v1/                      # API endpoints
├── models/
│   ├── chain.rb                     # Blockchain network model
│   ├── gas_reading.rb               # Gas price data model
│   └── bridge_route.rb              # Cross-chain route model
├── services/
│   └── gas_price_fetcher.rb         # RPC gas price fetching
├── jobs/
│   └── update_gas_prices_job.rb     # Background price updates
└── views/
    └── dashboard/
        └── index.html.erb           # Main dashboard UI
```

### Key Components

#### GasPriceFetcher Service

Handles fetching gas prices from blockchain RPC endpoints:

```ruby
# Fetch gas prices for all active chains
fetcher = GasPriceFetcher.new
fetcher.fetch_all_chains

# Fetch for specific chain
fetcher.fetch_gas_price_for_chain(chain)
```

#### UpdateGasPricesJob

Background job that runs every 60 seconds:

```ruby
# Enqueue job manually
UpdateGasPricesJob.perform_later

# Run immediately
UpdateGasPricesJob.perform_now
```

#### Models

- **Chain**: Represents blockchain networks
- **GasReading**: Stores gas price data points
- **BridgeRoute**: For future cross-chain routing features

## 🔧 Development

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/chain_test.rb

# Run with coverage
rails test --coverage
```

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Run Brakeman security scanner
bundle exec brakeman

# Auto-fix RuboCop issues
bundle exec rubocop -a
```

### Database Operations

```bash
# Create migration
rails generate migration AddFieldToModel field:type

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback

# Reset database
rails db:drop db:create db:migrate db:seed
```

### Adding New Chains

1. Add chain data to `db/seeds.rb`:

```ruby
{
  name: 'New Chain',
  chain_id: 12345,
  rpc_url: 'https://rpc.newchain.com',
  native_token: 'NEW',
  is_active: true
}
```

2. Run seeds:

```bash
rails db:seed
```

### Debugging

#### Check Gas Price Fetching

```bash
# Test RPC connection
rails runner "
chain = Chain.find_by(name: 'Ethereum')
fetcher = GasPriceFetcher.new
result = fetcher.fetch_gas_price_for_chain(chain)
puts result ? 'Success' : 'Failed'
"
```

#### Monitor Background Jobs

```bash
# Check job queue status
rails runner "puts SolidQueue::Job.count"

# View recent jobs
rails runner "SolidQueue::Job.order(created_at: :desc).limit(10).each { |job| puts job.inspect }"
```

#### Database Queries

```bash
# Check latest gas readings
rails runner "
GasReading.joins(:chain)
  .order(timestamp: :desc)
  .limit(10)
  .each { |r| puts '#{r.chain.name}: #{r.gas_price_gwei} gwei' }
"
```

## 🐳 Docker Development

### Services

The application uses Docker Compose for development dependencies:

```yaml
# PostgreSQL on port 5435
# Redis on port 6380
```

### Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f postgres
docker compose logs -f redis

# Rebuild services
docker compose down
docker compose up -d --build
```

## 🧪 Testing

### Test Structure

```
test/
├── controllers/
├── models/
├── jobs/
├── services/
├── fixtures/
└── integration/
```

### Running Specific Tests

```bash
# Model tests
rails test test/models/

# Controller tests
rails test test/controllers/

# Job tests
rails test test/jobs/

# Service tests
rails test test/services/
```

### Test Data

Test fixtures are located in `test/fixtures/`:

- `chains.yml`: Sample blockchain networks
- `gas_readings.yml`: Sample gas price data

## 🚀 Deployment

### Production Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:password@host:port/database

# Redis
REDIS_URL=redis://host:port/0

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key

# API Keys
COINGECKO_API_KEY=your_production_key
```

### Deployment Steps

1. **Prepare Assets**:
```bash
rails assets:precompile
```

2. **Database Migration**:
```bash
rails db:migrate RAILS_ENV=production
```

3. **Start Services**:
```bash
# Web server
rails server -e production

# Background jobs
bin/jobs
```

### Deployment Platforms

#### Heroku

```bash
# Add buildpacks
heroku buildpacks:add heroku/ruby
heroku buildpacks:add heroku/nodejs

# Set environment variables
heroku config:set RAILS_ENV=production
heroku config:set DATABASE_URL=...

# Deploy
git push heroku main
heroku run rails db:migrate
```

#### Railway

```bash
# Connect repository and deploy
# Set environment variables in Railway dashboard
```

#### VPS/Server

```bash
# Using systemd services
sudo systemctl enable gas_tracker_web
sudo systemctl enable gas_tracker_jobs
sudo systemctl start gas_tracker_web
sudo systemctl start gas_tracker_jobs
```

## 📈 Monitoring

### Application Health

- Health check endpoint: `/up`
- Monitor gas reading frequency
- Track job queue processing

### Key Metrics

- Gas price update frequency
- RPC endpoint response times
- Database query performance
- Background job success rate

### Logging

```bash
# View application logs
tail -f log/development.log

# View job logs
tail -f log/solid_queue.log

# Filter for specific chain
grep "Ethereum" log/development.log
```

## 🔧 Troubleshooting

### Common Issues

#### Docker Port Conflicts

If ports 5432, 6379 are in use:

```bash
# Check what's using the port
sudo lsof -i :5432

# Modify docker-compose.yml ports
# PostgreSQL: 5435:5432
# Redis: 6380:6379
```

#### Solid Queue Tables Missing

```bash
# Load queue schema manually
rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"
```

#### RPC Endpoint Failures

```bash
# Test RPC connectivity
curl -X POST https://eth.llamarpc.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}'
```

#### Tailwind CSS Not Loading

```bash
# Rebuild Tailwind
rails tailwindcss:build

# Check if bin/dev is running
ps aux | grep foreman
```

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run the test suite
6. Submit a pull request

### Code Standards

- Follow Rails conventions
- Use RuboCop for code style
- Write comprehensive tests
- Document new features

### Commit Messages

Use conventional commit format:

```
feat: add new blockchain network support
fix: resolve gas price calculation issue
docs: update API documentation
test: add integration tests for dashboard
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Rails team for the excellent framework
- LayerZero for cross-chain infrastructure inspiration
- Blockchain RPC providers for free endpoints
- Tailwind CSS for beautiful styling

## 📞 Support

For support and questions:

- Create an issue on GitHub
- Check the troubleshooting section
- Review the API documentation

---

Built with ❤️ using Rails 8 and Ruby 3.4.3
