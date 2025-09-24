# Cross-Chain Gas Tracker Development Plan

## Project Overview
A Rails application that tracks gas prices across LayerZero-supported blockchain networks and helps users find the most cost-effective routes for cross-chain transactions.

## MVP Features
- Real-time gas price monitoring for major chains
- Cross-chain bridge fee estimation
- Cost comparison and recommendations
- Historical gas price trends
- Simple, clean web interface

## Tech Stack
- **Backend:** Ruby on Rails 8.x
- **Ruby Version:** 3.4.3
- **Database:** PostgreSQL (via Docker)
- **Cache/Jobs:** Redis (via Docker) + Solid Queue
- **Frontend:** Rails views with Stimulus JS
- **Charts:** Chart.js or ApexCharts
- **Styling:** Tailwind CSS
- **APIs:** Web3 RPC endpoints, LayerZero APIs, CoinGecko
- **Containerization:** Docker Compose for development

---

## Phase 1: Project Setup (Week 1)

### Day 1-2: Rails Foundation & Docker Setup
- [ ] Create Docker Compose setup for PostgreSQL and Redis
- [ ] Initialize new Rails 8 application with Ruby 3.4.3
- [ ] Configure Rails to use Docker services
- [ ] Setup Solid Queue for background jobs (Rails 8 default)
- [ ] Configure authentication with Rails 8 built-in features
- [ ] Configure environment variables (.env file)
- [ ] Setup testing framework (Rails 8 built-in testing)

### Day 3-4: Core Models & Database
```ruby
# Create migrations and models
rails generate model Chain name:string chain_id:integer rpc_url:string native_token:string is_active:boolean
rails generate model GasReading chain:references gas_price_gwei:decimal usd_cost:decimal timestamp:datetime
rails generate model BridgeRoute source_chain:references destination_chain:references fee_usd:decimal updated_at:datetime
```

- [ ] Create and run migrations
- [ ] Setup model associations and validations
- [ ] Seed initial chain data (Ethereum, Polygon, Arbitrum, Optimism)
- [ ] Write basic model tests

### Day 5-7: Gas Price Fetching Service
- [ ] Create `GasPriceFetcher` service class
- [ ] Implement RPC calls for each chain
- [ ] Add error handling and timeouts
- [ ] Create Solid Queue job for periodic updates
- [ ] Test gas price fetching manually

**Deliverables:**
- Working Rails 8 app with Docker Compose setup
- Functional gas price fetching from 4 major chains
- Solid Queue job updating prices every 60 seconds

---

## Phase 2: Basic Web Interface (Week 2)

### Day 8-10: Controllers & Views
- [ ] Create `DashboardController` with index action
- [ ] Create `ChainsController` for individual chain details
- [ ] Build responsive dashboard layout
- [ ] Display current gas prices in table format
- [ ] Add color-coded indicators (green/yellow/red)
- [ ] Implement auto-refresh functionality

### Day 11-12: Styling & UX
- [ ] Setup Tailwind CSS (Rails 8 built-in support)
- [ ] Create responsive design for mobile/desktop
- [ ] Add loading states and error messages
- [ ] Implement basic sorting and filtering
- [ ] Add "last updated" timestamps

### Day 13-14: Bridge Fee Calculator
- [ ] Create simple form for bridge cost calculation
- [ ] Implement basic LayerZero fee estimation
- [ ] Display total transaction costs
- [ ] Add route comparison feature

**Deliverables:**
- Clean, responsive web interface
- Real-time gas price dashboard
- Basic bridge cost calculator

---

## Phase 3: Advanced Features (Week 3)

### Day 15-17: Historical Data & Charts
- [ ] Implement data retention strategy (keep 30 days)
- [ ] Create historical gas price charts
- [ ] Add time range selectors (24h, 7d, 30d)
- [ ] Implement chart interactions (zoom, hover details)
- [ ] Add gas price trend indicators

### Day 18-19: Smart Recommendations
- [ ] Create `RecommendationEngine` service
- [ ] Implement basic algorithms:
  - Current vs average price comparison
  - Time-of-day patterns
  - Weekend vs weekday analysis
- [ ] Add "Best time to bridge" suggestions
- [ ] Create recommendation display components

### Day 20-21: Performance Optimization
- [ ] Add database indexes for performance
- [ ] Implement Rails 8 caching features for frequently accessed data
- [ ] Optimize Solid Queue job schedules
- [ ] Add database cleanup jobs for old data
- [ ] Performance testing and monitoring

**Deliverables:**
- Historical gas price tracking
- Interactive charts and visualizations
- Smart recommendation system

---

## Phase 4: Polish & Production (Week 4)

### Day 22-24: Error Handling & Monitoring
- [ ] Comprehensive error handling for all APIs
- [ ] Add application monitoring (New Relic or similar)
- [ ] Implement fallback strategies for failed API calls
- [ ] Add health check endpoints
- [ ] Setup error notification system

### Day 25-26: Testing & Documentation
- [ ] Write comprehensive test suite
- [ ] Add API documentation
- [ ] Create user guide/help section
- [ ] Performance and security testing
- [ ] Code review and refactoring

### Day 27-28: Deployment
- [ ] Setup production environment (Heroku/Railway/VPS)
- [ ] Configure production database
- [ ] Setup domain and SSL
- [ ] Deploy application
- [ ] Monitor production deployment

**Deliverables:**
- Production-ready application
- Comprehensive testing and documentation
- Live deployment with monitoring

---

## Database Schema

```sql
-- chains table
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

-- gas_readings table  
CREATE TABLE gas_readings (
  id BIGSERIAL PRIMARY KEY,
  chain_id BIGINT REFERENCES chains(id),
  gas_price_gwei DECIMAL(20,9) NOT NULL,
  usd_cost DECIMAL(10,4),
  timestamp TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- bridge_routes table
CREATE TABLE bridge_routes (
  id BIGSERIAL PRIMARY KEY,
  source_chain_id BIGINT REFERENCES chains(id),
  destination_chain_id BIGINT REFERENCES chains(id),
  fee_usd DECIMAL(10,4),
  protocol VARCHAR DEFAULT 'stargate',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

---

## API Integrations

### Chain RPC Endpoints
```yaml
Ethereum: https://eth.llamarpc.com
Polygon: https://polygon-rpc.com
Arbitrum: https://arb1.arbitrum.io/rpc
Optimism: https://mainnet.optimism.io
BNB Chain: https://bsc-dataseed1.binance.org
Avalanche: https://api.avax.network/ext/bc/C/rpc
```

### External APIs
- **CoinGecko:** Token prices (100 calls/month free)
- **LayerZero:** Bridge fee estimation
- **Stargate Finance:** Cross-chain fee data
- **1inch API:** Alternative routing costs

---

## Environment Variables
```bash
# Database
DATABASE_URL=postgresql://...

# Redis
REDIS_URL=redis://localhost:6379

# API Keys
COINGECKO_API_KEY=your_key_here
LAYERZERO_API_KEY=your_key_here

# Chain RPCs
ETHEREUM_RPC=https://eth.llamarpc.com
POLYGON_RPC=https://polygon-rpc.com
ARBITRUM_RPC=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC=https://mainnet.optimism.io
```

---

## Folder Structure
```
app/
├── controllers/
│   ├── dashboard_controller.rb
│   ├── chains_controller.rb
│   └── api/v1/gas_prices_controller.rb
├── models/
│   ├── chain.rb
│   ├── gas_reading.rb
│   └── bridge_route.rb
├── services/
│   ├── gas_price_fetcher.rb
│   ├── bridge_fee_calculator.rb
│   └── recommendation_engine.rb
├── jobs/
│   ├── update_gas_prices_job.rb (Solid Queue)
│   └── cleanup_old_data_job.rb
└── views/
    ├── dashboard/
    ├── chains/
    └── layouts/
```

---

## Future Enhancements (Post-MVP)

### Phase 5: Advanced Features
- [ ] User accounts and watchlists
- [ ] Email/SMS price alerts
- [ ] Mobile app (React Native)
- [ ] API for third-party developers
- [ ] Advanced analytics dashboard

### Phase 6: Business Features
- [ ] Premium subscription tiers
- [ ] Affiliate integration with bridges
- [ ] White-label solutions
- [ ] Enterprise API access

---

## Success Metrics
- **Technical:** 99.9% uptime, <2s page load times
- **User:** 1000+ monthly active users
- **Data:** 95%+ accuracy in gas price reporting
- **Business:** Break-even on hosting costs

---

## Timeline Summary
- **Week 1:** Core Rails app + gas fetching
- **Week 2:** Web interface + basic features  
- **Week 3:** Historical data + recommendations
- **Week 4:** Polish + production deployment

**Total Development Time:** 4 weeks (1 developer)
**Budget Estimate:** $0-50/month (hosting + APIs)

---

## Getting Started Checklist
- [ ] Docker and Docker Compose installed
- [ ] Ruby 3.4.3 installed (rbenv recommended)
- [ ] Rails 8+ installed  
- [ ] Git repository initialized
- [ ] Free CoinGecko API key obtained

---

## Docker Setup

### Create `docker-compose.yml`
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: gas_tracker
      POSTGRES_PASSWORD: password
      POSTGRES_DB: gas_tracker_development
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U gas_tracker"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  postgres_test:
    image: postgres:16
    environment:
      POSTGRES_USER: gas_tracker
      POSTGRES_PASSWORD: password
      POSTGRES_DB: gas_tracker_test
    ports:
      - "5433:5432"
    volumes:
      - postgres_test_data:/var/lib/postgresql/data

volumes:
  postgres_data:
  postgres_test_data:
  redis_data:
```

### Create `.env.development`
```bash
# Database
DATABASE_URL=postgresql://gas_tracker:password@localhost:5432/gas_tracker_development

# Test Database
TEST_DATABASE_URL=postgresql://gas_tracker:password@localhost:5433/gas_tracker_test

# Redis
REDIS_URL=redis://localhost:6379/0

# Solid Queue
SOLID_QUEUE_ADAPTER=redis

# API Keys
COINGECKO_API_KEY=your_key_here
LAYERZERO_API_KEY=your_key_here

# Chain RPCs
ETHEREUM_RPC=https://eth.llamarpc.com
POLYGON_RPC=https://polygon-rpc.com
ARBITRUM_RPC=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC=https://mainnet.optimism.io
```

### Initial Setup Commands
```bash
# Start Docker services
docker-compose up -d

# Create new Rails 8 app
rails new gas_tracker --database=postgresql --skip-docker

# Add to Gemfile
gem 'solid_queue'
gem 'redis'
gem 'httparty'
gem 'dotenv-rails'

# Configure database.yml for Docker
# Update config/database.yml to use DATABASE_URL

# Install and setup
bundle install
rails generate solid_queue:install
rails db:create db:migrate
```