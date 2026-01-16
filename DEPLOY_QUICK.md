# Quick Deployment Reference

## TL;DR - Deploy in 5 Minutes

### 1. Setup (One-time)

```bash
# Get Base Sepolia ETH from faucet
# https://portal.cdp.coinbase.com/products/faucet

# Copy and edit .env
cp .env.example .env
nano .env  # Add your PRIVATE_KEY
```

### 2. Deploy

```bash
# Load environment
source .env

# Build
forge build

# Deploy
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvvv

  forge create script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --etherscan-api-key $BASESCAN_API_KEY \
    --verify
```

### 3. Save Addresses

Copy the output addresses:

- VenueManager: 0x...
- OracleManager: 0x...
- PerpAggregator: 0x...

## .env Template

```bash
PRIVATE_KEY=your_64_char_hex_key_without_0x
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key
```

## Get Resources

| Resource         | URL                                             |
| ---------------- | ----------------------------------------------- |
| Base Sepolia ETH | https://portal.cdp.coinbase.com/products/faucet |
| Alchemy RPC      | https://www.alchemy.com/                        |
| Basescan API Key | https://basescan.org/myapikey                   |
| Base Explorer    | https://sepolia.basescan.org/                   |

## Verify Deployment

```bash
# Check if deployed
cast code 0xYOUR_CONTRACT_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL

# Check owner
cast call 0xYOUR_PERP_AGGREGATOR "owner()" --rpc-url $BASE_SEPOLIA_RPC_URL
```

## Common Issues

| Issue               | Solution                                   |
| ------------------- | ------------------------------------------ |
| Insufficient funds  | Get more ETH from faucet                   |
| RPC error           | Use public RPC: `https://sepolia.base.org` |
| Private key error   | Remove `0x` prefix, ensure 64 hex chars    |
| Verification failed | Wait 2 min, try manual verification        |

## Manual Verification

```bash
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.24 \
  0xYOUR_CONTRACT_ADDRESS \
  src/ContractName.sol:ContractName \
  --etherscan-api-key $BASESCAN_API_KEY
```

## Full Guide

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete instructions.
