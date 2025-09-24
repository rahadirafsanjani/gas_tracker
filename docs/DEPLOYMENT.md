# Deployment Guide

This guide covers deploying the Cross-Chain Gas Tracker to various platforms and environments.

## Table of Contents

- [Production Requirements](#production-requirements)
- [Environment Configuration](#environment-configuration)
- [Database Setup](#database-setup)
- [Platform-Specific Deployments](#platform-specific-deployments)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Scaling Considerations](#scaling-considerations)
- [Security](#security)

## Production Requirements

### System Requirements

- **Ruby**: 3.4.3
- **Rails**: 8.0.2.1
- **PostgreSQL**: 16+ (with connection pooling)
- **Redis**: 7+ (for job queue and caching)
- **Memory**: Minimum 1GB RAM (recommended 2GB+)
- **Storage**: Minimum 10GB (grows with historical data)
- **CPU**: 1+ cores (recommended 2+ cores)

### External Services

- **RPC Endpoints**: Reliable blockchain RPC providers
- **Monitoring**: Application performance monitoring (APM)
- **Logging**: Centralized logging service
- **Backup**: Database backup solution

## Environment Configuration

### Required Environment Variables

```bash
# Application
RAILS_ENV=production
SECRET_KEY_BASE=your_64_character_secret_key

# Database
DATABASE_URL=postgresql://user:password@host:port/database
REDIS_URL=redis://host:port/0

# API Keys (Optional but recommended)
COINGECKO_API_KEY=your_coingecko_api_key
LAYERZERO_API_KEY=your_layerzero_api_key

# Chain RPC Endpoints
ETHEREUM_RPC=https://your-ethereum-rpc-endpoint
POLYGON_RPC=https://your-polygon-rpc-endpoint
ARBITRUM_RPC=https://your-arbitrum-rpc-endpoint
OPTIMISM_RPC=https://your-optimism-rpc-endpoint

# Performance
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
SOLID_QUEUE_WORKERS=2

# Monitoring
SENTRY_DSN=your_sentry_dsn
NEW_RELIC_LICENSE_KEY=your_new_relic_key
```

### Generating Secret Key

```bash
# Generate a secure secret key
rails secret
```

## Database Setup

### PostgreSQL Configuration

#### 1. Create Production Database

```sql
-- Connect as superuser
CREATE USER gas_tracker WITH PASSWORD 'secure_password';
CREATE DATABASE gas_tracker_production OWNER gas_tracker;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE gas_tracker_production TO gas_tracker;
```

#### 2. Optimize PostgreSQL Settings

Add to `postgresql.conf`:

```conf
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB

# Connection settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# Logging
log_statement = 'all'
log_min_duration_statement = 1000
```

#### 3. Database Migrations

```bash
# Run migrations
RAILS_ENV=production rails db:migrate

# Load Solid Queue schema
RAILS_ENV=production rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"

# Seed initial data
RAILS_ENV=production rails db:seed
```

### Redis Configuration

#### Production Redis Setup

```conf
# redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

## Platform-Specific Deployments

### Heroku

#### 1. Prepare Application

```bash
# Add Heroku buildpacks
heroku buildpacks:add heroku/ruby
heroku buildpacks:add heroku/nodejs

# Create Procfile
echo "web: bin/rails server -p \$PORT -e \$RAILS_ENV" > Procfile
echo "worker: bin/jobs" >> Procfile
```

#### 2. Configure Add-ons

```bash
# Add PostgreSQL
heroku addons:create heroku-postgresql:standard-0

# Add Redis
heroku addons:create heroku-redis:premium-0

# Add monitoring
heroku addons:create newrelic:wayne
```

#### 3. Set Environment Variables

```bash
heroku config:set RAILS_ENV=production
heroku config:set SECRET_KEY_BASE=$(rails secret)
heroku config:set COINGECKO_API_KEY=your_key
heroku config:set ETHEREUM_RPC=https://your-rpc-endpoint
```

#### 4. Deploy

```bash
# Deploy to Heroku
git push heroku main

# Run migrations
heroku run rails db:migrate

# Load Solid Queue schema
heroku run rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"

# Seed data
heroku run rails db:seed

# Scale workers
heroku ps:scale web=1 worker=1
```

### Railway

#### 1. Connect Repository

1. Visit [Railway](https://railway.app)
2. Connect your GitHub repository
3. Select the gas_tracker project

#### 2. Configure Services

```yaml
# railway.toml
[build]
builder = "nixpacks"

[deploy]
healthcheckPath = "/up"
restartPolicyType = "on_failure"

[[services]]
name = "web"
source = "."

[[services]]
name = "worker"
source = "."
startCommand = "bin/jobs"
```

#### 3. Environment Variables

Set in Railway dashboard:
- `RAILS_ENV=production`
- `SECRET_KEY_BASE=...`
- `DATABASE_URL=...` (auto-configured)
- `REDIS_URL=...` (auto-configured)

### DigitalOcean App Platform

#### 1. App Spec Configuration

```yaml
# .do/app.yaml
name: gas-tracker
services:
- name: web
  source_dir: /
  github:
    repo: your-username/gas-tracker
    branch: main
  run_command: bin/rails server -p $PORT -e $RAILS_ENV
  environment_slug: ruby
  instance_count: 1
  instance_size_slug: basic-xxs
  env:
  - key: RAILS_ENV
    value: production
  - key: SECRET_KEY_BASE
    value: your_secret_key

- name: worker
  source_dir: /
  github:
    repo: your-username/gas-tracker
    branch: main
  run_command: bin/jobs
  environment_slug: ruby
  instance_count: 1
  instance_size_slug: basic-xxs

databases:
- name: gas-tracker-db
  engine: PG
  version: "16"

- name: gas-tracker-redis
  engine: REDIS
  version: "7"
```

### VPS/Server Deployment

#### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl git build-essential postgresql postgresql-contrib redis-server nginx

# Install Ruby via rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
rbenv install 3.4.3
rbenv global 3.4.3
```

#### 2. Application Setup

```bash
# Clone repository
git clone https://github.com/your-username/gas-tracker.git
cd gas-tracker

# Install dependencies
bundle install --deployment --without development test

# Setup database
sudo -u postgres createuser gas_tracker
sudo -u postgres createdb gas_tracker_production -O gas_tracker

# Configure environment
cp .env.example .env.production
# Edit .env.production with production values

# Run migrations
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"
RAILS_ENV=production rails db:seed

# Precompile assets
RAILS_ENV=production rails assets:precompile
```

#### 3. Systemd Services

Create `/etc/systemd/system/gas-tracker-web.service`:

```ini
[Unit]
Description=Gas Tracker Web Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/gas-tracker
Environment=RAILS_ENV=production
EnvironmentFile=/home/deploy/gas-tracker/.env.production
ExecStart=/home/deploy/.rbenv/shims/bundle exec rails server -p 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/gas-tracker-worker.service`:

```ini
[Unit]
Description=Gas Tracker Background Jobs
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/gas-tracker
Environment=RAILS_ENV=production
EnvironmentFile=/home/deploy/gas-tracker/.env.production
ExecStart=/home/deploy/.rbenv/shims/bundle exec bin/jobs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### 4. Nginx Configuration

Create `/etc/nginx/sites-available/gas-tracker`:

```nginx
upstream gas_tracker {
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  server_name your-domain.com;
  
  # Redirect to HTTPS
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name your-domain.com;
  
  # SSL configuration
  ssl_certificate /path/to/certificate.crt;
  ssl_certificate_key /path/to/private.key;
  
  root /home/deploy/gas-tracker/public;
  
  location / {
    try_files $uri @gas_tracker;
  }
  
  location @gas_tracker {
    proxy_pass http://gas_tracker;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
  
  # Health check
  location /up {
    proxy_pass http://gas_tracker;
    access_log off;
  }
}
```

#### 5. Start Services

```bash
# Enable and start services
sudo systemctl enable gas-tracker-web gas-tracker-worker nginx
sudo systemctl start gas-tracker-web gas-tracker-worker nginx

# Check status
sudo systemctl status gas-tracker-web
sudo systemctl status gas-tracker-worker
```

## Monitoring and Maintenance

### Application Monitoring

#### New Relic Setup

```ruby
# Gemfile
gem 'newrelic_rpm'
```

```yaml
# config/newrelic.yml
production:
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: Gas Tracker Production
  monitor_mode: true
```

#### Sentry Error Tracking

```ruby
# Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'
```

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
end
```

### Health Checks

#### Application Health

```bash
# Check application health
curl https://your-domain.com/up

# Check database connectivity
rails runner "puts ActiveRecord::Base.connection.active? ? 'Connected' : 'Disconnected'"

# Check Redis connectivity
rails runner "puts Redis.new.ping"
```

#### Job Queue Monitoring

```bash
# Check job queue status
rails runner "puts 'Jobs in queue: ' + SolidQueue::Job.where(finished_at: nil).count.to_s"

# Check failed jobs
rails runner "SolidQueue::FailedExecution.includes(:job).each { |f| puts f.error }"
```

### Log Management

#### Centralized Logging

```ruby
# config/environments/production.rb
config.logger = ActiveSupport::Logger.new(STDOUT)
config.log_formatter = ::Logger::Formatter.new
config.log_level = :info
```

#### Log Rotation

```bash
# /etc/logrotate.d/gas-tracker
/home/deploy/gas-tracker/log/*.log {
  daily
  missingok
  rotate 30
  compress
  delaycompress
  notifempty
  create 0644 deploy deploy
  postrotate
    systemctl reload gas-tracker-web
    systemctl reload gas-tracker-worker
  endscript
}
```

### Database Maintenance

#### Regular Backups

```bash
#!/bin/bash
# backup-database.sh
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump gas_tracker_production | gzip > /backups/gas_tracker_$DATE.sql.gz

# Keep only last 30 days
find /backups -name "gas_tracker_*.sql.gz" -mtime +30 -delete
```

#### Data Cleanup

```bash
# Clean old gas readings (keep 30 days)
rails runner "GasReading.cleanup_old_data(30)"

# Clean old job records
rails runner "SolidQueue::Job.where('created_at < ?', 7.days.ago).delete_all"
```

## Scaling Considerations

### Horizontal Scaling

#### Load Balancer Configuration

```nginx
upstream gas_tracker_cluster {
  server app1.example.com:3000;
  server app2.example.com:3000;
  server app3.example.com:3000;
}
```

#### Database Read Replicas

```ruby
# config/database.yml
production:
  primary:
    url: <%= ENV['DATABASE_URL'] %>
  primary_replica:
    url: <%= ENV['DATABASE_REPLICA_URL'] %>
    replica: true
```

### Vertical Scaling

#### Memory Optimization

```bash
# Increase worker memory
export RAILS_MAX_THREADS=10
export WEB_CONCURRENCY=4
```

#### Database Optimization

```sql
-- Add indexes for performance
CREATE INDEX CONCURRENTLY idx_gas_readings_chain_timestamp 
ON gas_readings (chain_id, timestamp DESC);

CREATE INDEX CONCURRENTLY idx_gas_readings_timestamp 
ON gas_readings (timestamp DESC);
```

### Caching Strategy

#### Redis Caching

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

#### Application-Level Caching

```ruby
# In controllers
def index
  @chains = Rails.cache.fetch('active_chains', expires_in: 5.minutes) do
    Chain.active.includes(:gas_readings)
  end
end
```

## Security

### SSL/TLS Configuration

```bash
# Install Let's Encrypt certificate
sudo certbot --nginx -d your-domain.com
```

### Database Security

```sql
-- Restrict database permissions
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO gas_tracker;
GRANT ALL ON ALL TABLES IN SCHEMA public TO gas_tracker;
```

### Application Security

```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = { hsts: { expires: 1.year } }
```

### Firewall Configuration

```bash
# UFW firewall rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 3000/tcp   # Block direct app access
sudo ufw enable
```

## Troubleshooting

### Common Issues

#### High Memory Usage

```bash
# Monitor memory usage
free -h
ps aux --sort=-%mem | head

# Optimize Ruby memory
export RUBY_GC_HEAP_GROWTH_FACTOR=1.1
export RUBY_GC_MALLOC_LIMIT=16000000
```

#### Database Connection Issues

```bash
# Check connection pool
rails runner "puts ActiveRecord::Base.connection_pool.stat"

# Increase connection pool
export RAILS_MAX_THREADS=10
```

#### Job Queue Backlog

```bash
# Check queue status
rails runner "puts SolidQueue::Job.where(finished_at: nil).count"

# Scale workers
sudo systemctl start gas-tracker-worker@2
sudo systemctl start gas-tracker-worker@3
```

### Performance Monitoring

```bash
# Monitor application performance
curl -w "@curl-format.txt" -o /dev/null -s "https://your-domain.com/"

# Database performance
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

This deployment guide provides comprehensive instructions for deploying the Gas Tracker application to various platforms while ensuring security, scalability, and maintainability.
