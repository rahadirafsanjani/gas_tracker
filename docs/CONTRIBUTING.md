# Contributing to Cross-Chain Gas Tracker

Thank you for your interest in contributing to the Cross-Chain Gas Tracker! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)

## Code of Conduct

### Our Pledge

We are committed to making participation in this project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team. All complaints will be reviewed and investigated promptly and fairly.

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Ruby 3.4.3 installed
- Rails 8.0.2.1 or later
- Docker and Docker Compose
- Git configured with your name and email
- A GitHub account

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/your-username/gas-tracker.git
   cd gas-tracker
   ```

2. **Set up upstream remote**
   ```bash
   git remote add upstream https://github.com/original-owner/gas-tracker.git
   ```

3. **Install dependencies**
   ```bash
   bundle install
   gem install foreman
   ```

4. **Setup environment**
   ```bash
   cp env.example .env
   # Edit .env with your local configuration
   ```

5. **Start services**
   ```bash
   docker compose up -d
   rails db:create db:migrate
   rails runner "ActiveRecord::Schema.define { load Rails.root.join('db/queue_schema.rb') }"
   rails db:seed
   ```

6. **Run the application**
   ```bash
   bin/dev
   ```

## Development Workflow

### Branch Naming Convention

Use descriptive branch names with prefixes:

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test improvements
- `chore/` - Maintenance tasks

Examples:
```bash
feature/add-historical-charts
fix/gas-price-calculation-error
docs/update-api-documentation
refactor/improve-service-layer
```

### Development Process

1. **Create a feature branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run the full test suite
   rails test
   
   # Run specific tests
   rails test test/models/chain_test.rb
   
   # Run code quality checks
   bundle exec rubocop
   bundle exec brakeman
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add historical gas price charts"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

## Coding Standards

### Ruby Style Guide

We follow the [Ruby Style Guide](https://rubystyle.guide/) with these specific preferences:

```ruby
# Use double quotes for strings
message = "Hello, world!"

# Use trailing commas in multi-line collections
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

# Use descriptive variable names
gas_price_in_gwei = fetch_gas_price(chain)
current_timestamp = Time.current
```

### Rails Conventions

- Follow Rails naming conventions
- Use ActiveRecord associations and validations
- Prefer service objects for complex business logic
- Use strong parameters in controllers
- Follow RESTful routing conventions

### Code Organization

```ruby
# Controllers should be thin
class DashboardController < ApplicationController
  def index
    @dashboard_data = DashboardService.call
  end
end

# Services should handle business logic
class DashboardService < ApplicationService
  def call
    # Complex logic here
  end
end

# Models should focus on data and simple business rules
class Chain < ApplicationRecord
  validates :name, presence: true
  
  def latest_gas_reading
    gas_readings.order(timestamp: :desc).first
  end
end
```

### Database Guidelines

- Use descriptive migration names
- Add indexes for performance
- Use foreign key constraints
- Include rollback logic in migrations

```ruby
class AddIndexToGasReadingsTimestamp < ActiveRecord::Migration[8.0]
  def change
    add_index :gas_readings, [:chain_id, :timestamp], 
              name: 'idx_gas_readings_chain_timestamp'
  end
end
```

## Testing Guidelines

### Test Structure

```
test/
├── controllers/     # Controller tests
├── models/         # Model tests
├── services/       # Service tests
├── jobs/          # Job tests
├── integration/   # Integration tests
├── fixtures/      # Test data
└── support/       # Test helpers
```

### Writing Tests

1. **Model Tests**
   ```ruby
   class ChainTest < ActiveSupport::TestCase
     test "should be valid with valid attributes" do
       chain = chains(:ethereum)
       assert chain.valid?
     end
     
     test "should require name" do
       chain = Chain.new
       assert_not chain.valid?
       assert_includes chain.errors[:name], "can't be blank"
     end
   end
   ```

2. **Service Tests**
   ```ruby
   class GasPriceFetcherTest < ActiveSupport::TestCase
     test "successfully fetches gas price" do
       stub_rpc_response
       
       result = GasPriceFetcher.call(chains(:ethereum))
       
       assert result.success?
       assert_instance_of GasReading, result.data
     end
   end
   ```

3. **Controller Tests**
   ```ruby
   class DashboardControllerTest < ActionDispatch::IntegrationTest
     test "should get index" do
       get root_path
       assert_response :success
       assert_select "h1", text: "Cross-Chain Gas Tracker"
     end
   end
   ```

### Test Coverage

- Aim for 90%+ test coverage
- Test happy paths and edge cases
- Include integration tests for critical flows
- Mock external API calls

## Documentation

### Code Documentation

- Add comments for complex algorithms
- Document public API methods
- Include examples in documentation
- Keep README up to date

```ruby
# Fetches gas price from blockchain RPC endpoint
# 
# @param chain [Chain] The blockchain network to query
# @return [ServiceResult] Success with GasReading or failure with error
#
# @example
#   result = GasPriceFetcher.call(ethereum_chain)
#   if result.success?
#     puts "Gas price: #{result.data.gas_price_gwei} gwei"
#   end
def self.call(chain)
  # Implementation
end
```

### API Documentation

- Document all API endpoints
- Include request/response examples
- Specify parameter types and requirements
- Document error codes and messages

### Changelog

- Update CHANGELOG.md for significant changes
- Follow semantic versioning
- Include migration notes for breaking changes

## Submitting Changes

### Pull Request Process

1. **Ensure your PR is ready**
   - All tests pass
   - Code follows style guidelines
   - Documentation is updated
   - No merge conflicts

2. **Write a clear PR description**
   ```markdown
   ## Description
   Brief description of the changes
   
   ## Type of Change
   - [ ] Bug fix
   - [x] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [x] Unit tests pass
   - [x] Integration tests pass
   - [x] Manual testing completed
   
   ## Screenshots (if applicable)
   [Include screenshots for UI changes]
   ```

3. **Request review**
   - Assign appropriate reviewers
   - Respond to feedback promptly
   - Make requested changes

### Commit Message Format

Use conventional commit format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Examples:
```
feat(api): add historical gas price endpoint
fix(dashboard): resolve price display issue
docs(readme): update installation instructions
test(services): add gas price fetcher tests
```

## Issue Reporting

### Bug Reports

When reporting bugs, include:

1. **Bug description**
   - Clear, concise description
   - Expected vs actual behavior

2. **Reproduction steps**
   ```
   1. Go to dashboard
   2. Click on Ethereum chain
   3. Observe incorrect gas price display
   ```

3. **Environment information**
   - Ruby version
   - Rails version
   - Operating system
   - Browser (if applicable)

4. **Additional context**
   - Error messages
   - Screenshots
   - Log output

### Bug Report Template

```markdown
**Bug Description**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected Behavior**
A clear description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
- Ruby version: [e.g. 3.4.3]
- Rails version: [e.g. 8.0.2.1]
- OS: [e.g. macOS, Ubuntu 22.04]
- Browser: [e.g. Chrome 91, Firefox 89]

**Additional Context**
Add any other context about the problem here.
```

## Feature Requests

### Proposing New Features

1. **Check existing issues** - Ensure the feature hasn't been requested
2. **Describe the feature** - Clear description of functionality
3. **Explain the use case** - Why is this feature needed?
4. **Consider implementation** - How might it be implemented?

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request.

**Implementation ideas**
If you have ideas about how to implement this feature.
```

## Development Guidelines

### Adding New Blockchain Networks

1. **Update seeds.rb**
   ```ruby
   {
     name: 'New Chain',
     chain_id: 12345,
     rpc_url: 'https://rpc.newchain.com',
     native_token: 'NEW',
     is_active: true
   }
   ```

2. **Add RPC endpoint to environment**
   ```bash
   NEW_CHAIN_RPC=https://rpc.newchain.com
   ```

3. **Test gas price fetching**
   ```ruby
   chain = Chain.find_by(name: 'New Chain')
   result = GasPriceFetcher.call(chain)
   ```

4. **Update documentation**
   - Add to supported networks list
   - Update API documentation
   - Include in README

### Performance Considerations

- Use database indexes appropriately
- Implement caching for expensive operations
- Consider background job processing for long-running tasks
- Monitor memory usage and optimize queries

### Security Considerations

- Validate all user inputs
- Use parameterized queries
- Implement rate limiting for APIs
- Secure sensitive configuration

## Community

### Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check docs/ directory for detailed guides

### Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- Release notes for major features

Thank you for contributing to Cross-Chain Gas Tracker! 🚀
