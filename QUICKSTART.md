# Quick Start Guide

Get the Base Perpetual DEX Aggregator up and running in minutes.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git installed
- Basic understanding of Solidity and DeFi

## Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd base-dex-aggreg

# Install dependencies
forge install

# Build the project
forge build
```

## Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/Integration.t.sol -vv

# Run with coverage
forge coverage
```

## Project Structure

```
src/
├── PerpAggregator.sol       # Main entry point
├── VenueManager.sol         # Venue registry
├── OracleManager.sol        # Price validation
└── interfaces/              # Standard interfaces

test/
├── PerpAggregator.t.sol     # Core tests
├── VenueManager.t.sol       # Venue tests
├── OracleManager.t.sol      # Oracle tests
├── Integration.t.sol        # E2E tests
└── mocks/                   # Mock contracts
```

## Key Contracts

### PerpAggregator

Main contract for opening/closing positions. Routes to best venue.

### VenueManager

Registry of perpetual DEX venues (GMX, Synthetix, etc.)

### OracleManager

Validates prices using Chainlink-style oracles.

## Usage Examples

### Opening a Position

```solidity
// Open a 10x long position on ETH
uint256 executedSize = perpAggregator.openPosition(
    ethMarket,              // market address
    true,                   // isLong
    1000e18,                // margin (1000 USDC)
    10,                     // leverage (10x)
    minOut,                 // slippage protection
    block.timestamp + 15 minutes  // deadline
);
```

### Closing a Position

```solidity
uint256 payout = perpAggregator.closePosition(
    ethMarket,
    positionSize,
    minOut,
    block.timestamp + 15 minutes
);
```

## Deployment

### Local Testing

```bash
# Start local node
anvil

# Deploy to local node
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Base Testnet

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export BASE_SEPOLIA_RPC_URL=your_rpc_url

# Deploy
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Base Mainnet

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export BASE_RPC_URL=your_rpc_url

# Deploy
forge script script/Deploy.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify
```

## Post-Deployment Setup

After deployment, you need to:

1. **Register Venues**

```solidity
venueManager.registerVenue(
    gmxAddress,
    "GMX",
    50,  // max leverage
    10   // fee in bps
);
```

2. **Set Oracles**

```solidity
oracleManager.setOracle(
    ethMarket,
    chainlinkEthUsdAddress
);
```

3. **Test with Small Position**

```solidity
// Open a small test position
perpAggregator.openPosition(
    ethMarket,
    true,
    10e18,  // 10 USDC
    2,      // 2x leverage
    0,
    block.timestamp + 1 hours
);
```

## Common Commands

```bash
# Format code
forge fmt

# Check contract sizes
forge build --sizes

# Run specific test
forge test --match-test test_OpenPosition_Success -vvv

# Generate gas snapshot
forge snapshot

# Clean build artifacts
forge clean
```

## Troubleshooting

### Tests Failing

```bash
# Clean and rebuild
forge clean
forge build
forge test
```

### Deployment Issues

- Ensure you have enough ETH for gas
- Check RPC URL is correct
- Verify private key is set correctly

### Contract Size Too Large

All contracts are well within the 24KB limit:

- PerpAggregator: 8,077 bytes
- VenueManager: 6,208 bytes
- OracleManager: 3,427 bytes

## Next Steps

1. **Read the Documentation**

   - [README.md](README.md) - Full documentation
   - [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Architecture details
   - [SUMMARY.md](SUMMARY.md) - Implementation summary

2. **Explore the Tests**

   - Check out `test/Integration.t.sol` for E2E examples
   - Run tests with `-vv` flag to see detailed logs

3. **Customize for Your Needs**
   - Add real venue integrations
   - Implement position tracking
   - Add liquidation system

## Security Notes

⚠️ **Important**: This is a demo/portfolio project. For production:

- Conduct professional security audit
- Test extensively on testnet
- Start with small position limits
- Monitor for unusual activity
- Have emergency pause mechanism ready

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Base Docs](https://docs.base.org/)
- [OpenZeppelin](https://docs.openzeppelin.com/)

## Support

For issues or questions:

1. Check existing documentation
2. Review test files for examples
3. Open an issue on GitHub

---

**Happy Building!** 🚀
