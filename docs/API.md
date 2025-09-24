# API Documentation

This document provides comprehensive documentation for the Cross-Chain Gas Tracker API.

## Base URL

```
http://localhost:3000/api/v1
```

## Authentication

Currently, the API does not require authentication. All endpoints are publicly accessible.

## Response Format

All API responses follow a consistent JSON format:

```json
{
  "data": {...},
  "meta": {
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

## Error Handling

Error responses include appropriate HTTP status codes and error messages:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Chain not found",
    "details": "No chain found with ID: 999"
  },
  "meta": {
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

## Endpoints

### Chains

#### GET /api/v1/chains

Retrieve all supported blockchain networks.

**Parameters:**
- `active` (optional): Filter by active status (true/false)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/chains?active=true"
```

**Example Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Ethereum",
      "chain_id": 1,
      "rpc_url": "https://eth.llamarpc.com",
      "native_token": "ETH",
      "is_active": true,
      "created_at": "2025-09-24T04:30:00.000Z",
      "updated_at": "2025-09-24T04:30:00.000Z"
    },
    {
      "id": 2,
      "name": "Polygon",
      "chain_id": 137,
      "rpc_url": "https://polygon-rpc.com",
      "native_token": "MATIC",
      "is_active": true,
      "created_at": "2025-09-24T04:30:00.000Z",
      "updated_at": "2025-09-24T04:30:00.000Z"
    }
  ],
  "meta": {
    "total_count": 6,
    "active_count": 6,
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

#### GET /api/v1/chains/:id

Retrieve details for a specific blockchain network.

**Parameters:**
- `id` (required): Chain ID

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/chains/1"
```

**Example Response:**
```json
{
  "data": {
    "id": 1,
    "name": "Ethereum",
    "chain_id": 1,
    "rpc_url": "https://eth.llamarpc.com",
    "native_token": "ETH",
    "is_active": true,
    "latest_gas_reading": {
      "id": 123,
      "gas_price_gwei": "25.5",
      "usd_cost": null,
      "timestamp": "2025-09-24T04:38:35.000Z"
    },
    "average_gas_price_24h": "28.7",
    "readings_count": 1440,
    "created_at": "2025-09-24T04:30:00.000Z",
    "updated_at": "2025-09-24T04:30:00.000Z"
  },
  "meta": {
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

### Gas Prices

#### GET /api/v1/gas_prices

Retrieve current gas prices for all active chains.

**Parameters:**
- `chain_ids` (optional): Comma-separated list of chain IDs to filter
- `limit` (optional): Maximum number of results (default: 50)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/gas_prices?chain_ids=1,137&limit=10"
```

**Example Response:**
```json
{
  "data": [
    {
      "chain": {
        "id": 1,
        "name": "Ethereum",
        "chain_id": 1,
        "native_token": "ETH"
      },
      "gas_reading": {
        "id": 123,
        "gas_price_gwei": "25.5",
        "usd_cost": null,
        "timestamp": "2025-09-24T04:38:35.000Z",
        "status": "active"
      },
      "statistics": {
        "average_24h": "28.7",
        "min_24h": "15.2",
        "max_24h": "45.8",
        "trend": "decreasing"
      }
    },
    {
      "chain": {
        "id": 2,
        "name": "Polygon",
        "chain_id": 137,
        "native_token": "MATIC"
      },
      "gas_reading": {
        "id": 124,
        "gas_price_gwei": "30.2",
        "usd_cost": null,
        "timestamp": "2025-09-24T04:38:33.000Z",
        "status": "active"
      },
      "statistics": {
        "average_24h": "32.1",
        "min_24h": "25.0",
        "max_24h": "50.5",
        "trend": "stable"
      }
    }
  ],
  "meta": {
    "total_count": 6,
    "last_updated": "2025-09-24T04:38:35.000Z",
    "update_frequency": "60 seconds",
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

#### GET /api/v1/gas_prices/:chain_id

Retrieve gas price data for a specific chain.

**Parameters:**
- `chain_id` (required): Chain ID
- `hours` (optional): Number of hours of historical data (default: 24, max: 168)
- `interval` (optional): Data interval in minutes (default: 60)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/gas_prices/1?hours=24&interval=60"
```

**Example Response:**
```json
{
  "data": {
    "chain": {
      "id": 1,
      "name": "Ethereum",
      "chain_id": 1,
      "native_token": "ETH"
    },
    "current_reading": {
      "gas_price_gwei": "25.5",
      "usd_cost": null,
      "timestamp": "2025-09-24T04:38:35.000Z"
    },
    "historical_data": [
      {
        "gas_price_gwei": "24.8",
        "timestamp": "2025-09-24T03:38:35.000Z"
      },
      {
        "gas_price_gwei": "26.2",
        "timestamp": "2025-09-24T02:38:35.000Z"
      }
    ],
    "statistics": {
      "average": "28.7",
      "min": "15.2",
      "max": "45.8",
      "median": "27.3",
      "std_deviation": "8.4",
      "trend": "decreasing",
      "volatility": "moderate"
    }
  },
  "meta": {
    "data_points": 24,
    "time_range": "24 hours",
    "interval": "60 minutes",
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

### Bridge Routes (Future Feature)

#### GET /api/v1/bridge_routes

Retrieve available cross-chain bridge routes.

**Parameters:**
- `source_chain_id` (optional): Source chain ID
- `destination_chain_id` (optional): Destination chain ID
- `protocol` (optional): Bridge protocol (stargate, layerzero, etc.)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/bridge_routes?source_chain_id=1&destination_chain_id=137"
```

**Example Response:**
```json
{
  "data": [
    {
      "id": 1,
      "source_chain": {
        "id": 1,
        "name": "Ethereum",
        "chain_id": 1
      },
      "destination_chain": {
        "id": 2,
        "name": "Polygon",
        "chain_id": 137
      },
      "fee_usd": "5.50",
      "protocol": "stargate",
      "estimated_time": "15 minutes",
      "last_updated": "2025-09-24T04:30:00.000Z"
    }
  ],
  "meta": {
    "total_routes": 30,
    "timestamp": "2025-09-24T04:38:35.000Z",
    "version": "1.0"
  }
}
```

## Rate Limiting

Currently, there are no rate limits implemented. However, we recommend:

- Maximum 100 requests per minute per IP
- Use caching for frequently accessed data
- Implement exponential backoff for retries

## Webhooks (Future Feature)

The API will support webhooks for real-time gas price updates:

```json
{
  "event": "gas_price_updated",
  "chain_id": 1,
  "data": {
    "gas_price_gwei": "25.5",
    "timestamp": "2025-09-24T04:38:35.000Z",
    "change_percentage": -2.5
  }
}
```

## SDK Examples

### JavaScript/Node.js

```javascript
const GasTracker = require('gas-tracker-sdk');

const client = new GasTracker({
  baseUrl: 'http://localhost:3000/api/v1'
});

// Get all gas prices
const gasPrices = await client.gasPrices.getAll();

// Get specific chain data
const ethereumData = await client.gasPrices.getByChain(1);

// Get historical data
const historicalData = await client.gasPrices.getHistorical(1, { hours: 24 });
```

### Python

```python
import requests

class GasTracker:
    def __init__(self, base_url='http://localhost:3000/api/v1'):
        self.base_url = base_url
    
    def get_gas_prices(self, chain_ids=None):
        url = f"{self.base_url}/gas_prices"
        params = {'chain_ids': ','.join(map(str, chain_ids))} if chain_ids else {}
        response = requests.get(url, params=params)
        return response.json()
    
    def get_chain_data(self, chain_id, hours=24):
        url = f"{self.base_url}/gas_prices/{chain_id}"
        params = {'hours': hours}
        response = requests.get(url, params=params)
        return response.json()

# Usage
tracker = GasTracker()
gas_prices = tracker.get_gas_prices([1, 137])
ethereum_data = tracker.get_chain_data(1, hours=48)
```

### cURL Examples

```bash
# Get all active chains
curl -X GET "http://localhost:3000/api/v1/chains?active=true" \
  -H "Accept: application/json"

# Get current gas prices
curl -X GET "http://localhost:3000/api/v1/gas_prices" \
  -H "Accept: application/json"

# Get Ethereum historical data
curl -X GET "http://localhost:3000/api/v1/gas_prices/1?hours=24" \
  -H "Accept: application/json"

# Get specific chains gas prices
curl -X GET "http://localhost:3000/api/v1/gas_prices?chain_ids=1,137,42161" \
  -H "Accept: application/json"
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `RESOURCE_NOT_FOUND` | 404 | Requested resource not found |
| `INVALID_PARAMETERS` | 400 | Invalid request parameters |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

## Changelog

### Version 1.0 (Current)
- Initial API release
- Basic chains and gas prices endpoints
- JSON response format
- Error handling

### Future Versions
- v1.1: Bridge routes implementation
- v1.2: Webhooks support
- v1.3: Authentication and rate limiting
- v2.0: GraphQL endpoint
