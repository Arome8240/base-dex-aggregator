# Base Perpetual DEX Aggregator

A non-custodial, on-chain perpetual futures aggregator deployed on Base (Ethereum L2). This protocol routes leveraged perpetual trades to the best execution venue across multiple DEXs.

## 🏗️ Architecture

### Core Contracts

- **PerpAggregator.sol** - Main entry point for all user actions. Handles position management and venue selection.
- **VenueManager.sol** - Registry for perpetual DEX venues with metadata (fees, max leverage, supported markets).
- **OracleManager.sol** - Price validation using Chainlink-style oracles to prevent manipulation.
- **IVenue.sol** - Standard interface that all perpetual venues must implement.

### Key Features

✅ **Multi-venue aggregation** - Routes trades to the best execution price
✅ **Oracle price validation** - Prevents price manipulation and stale data
✅ **Slippage protection** - User-defined minimum output amounts
✅ **Deadline protection** - Time-bound transactions
✅ **Pausable** - Emergency stop mechanism
✅ **Reentrancy protection** - Secure against reentrancy attacks
✅ **Gas optimized** - Efficient venue selection algorithm

## 🔐 Security Features

- Checks-effects-interactions pattern
- Reentrancy guards on all state-changing functions
- Deadline and slippage validation
- Oracle price deviation limits (default 5%)
- Pausable admin controls
- Explicit revert reasons for debugging

## 🧪 Testing

Comprehensive Foundry test suite covering:

- ✅ Happy path flows (open → increase → reduce → close)
- ✅ Slippage failures
- ✅ Oracle price validation
- ✅ Access control
- ✅ Edge cases (zero margin, max leverage)
- ✅ Fuzz tests for position sizes and parameters

### Run Tests

````bash
# Run all tests
forge ploy

```un with verbosity
forge test -vv

# Run specific test file
forge test --match-path test/PerpAggregator.t.sol

# Run with gas reporting
forge test --gas-report
````

### Test Coverage

```bash
forge coverage
```

## 🚀 Deployment

### Prerequisites

- Foundry installed
- Base RPC endpoint
- Deployer wallet with ETH on Base

### Deploy Script

```bash
# Deploy to Base mainnet
forge script script/Deploy.s.sol --rpc-url $BASE_RPC_URL --broadcast --verify

# Deploy to Base Sepolia testnet
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify
```

## 📖 Usage

### Opening a Position

```solidity
// Open a 10x long position on ETH with 1000 USDC margin
uint256 executedSize = perpAggregator.openPosition(
    ethMarket,        // market address
    true,             // isLong
    1000e18,          // margin (1000 USDC)
    10,               // leverage (10x)
    minOut,           // minimum position size (slippage protection)
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

### Increasing a Position

```solidity
uint256 additionalSize = perpAggregator.increasePosition(
    ethMarket,
    500e18,  // additional margin
    10,      // leverage
    minOut,
    block.timestamp + 15 minutes
);
```

### Reducing a Position

```solidity
uint256 payout = perpAggregator.reducePosition(
    ethMarket,
    sizeToReduce,
    minOut,
    block.timestamp + 15 minutes
);
```

## 🔧 Admin Functions

### Register a Venue

```solidity
venueManager.registerVenue(
    venueAddress,
    "GMX",     // venue name
    50,        // max leverage (50x)
    10         // fee in basis points (0.1%)
);
```

### Set Oracle

```solidity
oracleManager.setOracle(
    ethMarket,
    chainlinkOracleAddress
);
```

### Pause/Unpause

```solidity
perpAggregator.pause();
perpAggregator.unpause();
```

## 📊 Contract Addresses (Base Mainnet)

_To be deployed_

## 🛠️ Development

### Build

```bash
forge build
```

### Format

```bash
forge fmt
```

### Local Testing

```bash
# Start local node
anvil

# Run tests against local node
forge test --fork-url http://localhost:8545
```

## 📝 Assumptions & Limitations (v1)

- Mock venues used for testing (integrate real venues in production)
- No liquidation bot system (v2 feature)
- No funding rate settlement (v2 feature)
- Margin assumed to be USDC
- Simplified venue selection for close/increase/reduce (tracks first active venue)

## 🔮 Future Enhancements (v2)

- [ ] Position tracking per user per venue
- [ ] Liquidation system with keeper incentives
- [ ] Funding rate calculations
- [ ] Multi-collateral support (ETH, WBTC, etc.)
- [ ] Advanced routing algorithms (split orders across venues)
- [ ] Limit orders
- [ ] Stop-loss / take-profit orders
- [ ] Integration with real venues (GMX, Synthetix, etc.)

## 📄 License

MIT

## 🤝 Contributing

This is a portfolio/demo project. For production use, conduct thorough audits.

---

**Built with Foundry on Base** 🔵
