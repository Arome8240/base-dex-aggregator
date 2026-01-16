# Project Structure

```
base-dex-aggreg/
├── src/
│   ├── PerpAggregator.sol          # Main aggregator contract (entry point)
│   ├── VenueManager.sol            # Venue registry and management
│   ├── OracleManager.sol           # Price oracle validation
│   └── interfaces/
│       ├── IVenue.sol              # Standard venue interface
│       ├── IPerpAggregator.sol     # Aggregator interface
│       └── IOracle.sol             # Oracle interface
│
├── test/
│   ├── PerpAggregator.t.sol        # Core aggregator tests (17 tests)
│   ├── VenueManager.t.sol          # Venue management tests (11 tests)
│   ├── OracleManager.t.sol         # Oracle tests (11 tests)
│   ├── Integration.t.sol           # End-to-end integration tests (4 tests)
│   └── mocks/
│       ├── MockVenue.sol           # Mock perpetual venue
│       └── MockOracle.sol          # Mock price oracle
│
├── script/
│   └── Deploy.s.sol                # Deployment script for Base
│
├── lib/
│   └── forge-std/                  # Foundry standard library
│
├── foundry.toml                    # Foundry configuration
├── README.md                       # Project documentation
├── COMMITS.md                      # Suggested commit structure
└── PROJECT_STRUCTURE.md            # This file
```

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User / Trader                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     PerpAggregator.sol                       │
│  • openPosition()                                            │
│  • closePosition()                                           │
│  • increasePosition()                                        │
│  • reducePosition()                                          │
│  • Venue selection logic                                     │
│  • Reentrancy protection                                     │
│  • Pausable controls                                         │
└──────────────┬────────────────────────────┬─────────────────┘
               │                            │
               ▼                            ▼
┌──────────────────────────┐  ┌────────────────────────────┐
│   VenueManager.sol       │  │   OracleManager.sol        │
│  • registerVenue()       │  │  • setOracle()             │
│  • removeVenue()         │  │  • getLatestPrice()        │
│  • getActiveVenues()     │  │  • validatePrice()         │
│  • Venue metadata        │  │  • Price staleness check   │
└──────────┬───────────────┘  └────────────┬───────────────┘
           │                               │
           ▼                               ▼
┌──────────────────────┐      ┌────────────────────────────┐
│  IVenue Interface    │      │  IOracle Interface         │
│  (GMX, Synthetix,    │      │  (Chainlink, etc.)         │
│   Kwenta, etc.)      │      │                            │
└──────────────────────┘      └────────────────────────────┘
```

## Data Flow: Opening a Position

```
1. User calls openPosition()
   ↓
2. PerpAggregator validates inputs (margin, leverage, deadline)
   ↓
3. Query VenueManager for active venues
   ↓
4. For each venue:
   - Get quote (price + fees)
   - Check leverage limits
   - Calculate effective price
   ↓
5. Select best venue (lowest price for longs, highest for shorts)
   ↓
6. Get execution price from selected venue
   ↓
7. Validate price against OracleManager
   - Check price staleness
   - Check price deviation (< 5%)
   ↓
8. Execute position on selected venue
   ↓
9. Check slippage (executedSize >= minOut)
   ↓
10. Emit PositionOpened event
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Measures                         │
├─────────────────────────────────────────────────────────────┤
│ 1. Reentrancy Guard        → Prevents reentrancy attacks    │
│ 2. Deadline Check          → Prevents stale transactions    │
│ 3. Slippage Protection     → User-defined minOut            │
│ 4. Oracle Validation       → Prevents price manipulation    │
│ 5. Price Staleness Check   → Max 15 minutes old             │
│ 6. Price Deviation Limit   → Max 5% from oracle             │
│ 7. Pausable                → Emergency stop mechanism       │
│ 8. Access Control          → Owner-only admin functions     │
│ 9. Input Validation        → Zero checks, bounds checks     │
│ 10. CEI Pattern            → Checks-Effects-Interactions    │
└─────────────────────────────────────────────────────────────┘
```

## Test Coverage

```
Total Tests: 43
├── PerpAggregator.t.sol:    17 tests (including 2 fuzz tests)
├── VenueManager.t.sol:      11 tests (including 1 fuzz test)
├── OracleManager.t.sol:     11 tests (including 2 fuzz tests)
└── Integration.t.sol:        4 tests (end-to-end scenarios)

Test Categories:
✅ Happy path flows
✅ Access control
✅ Input validation
✅ Slippage protection
✅ Oracle validation
✅ Venue selection
✅ Edge cases
✅ Fuzz testing
✅ Integration scenarios
```

## Gas Costs (Approximate)

```
Contract Deployment:
├── OracleManager:    ~835,000 gas
├── VenueManager:     ~1,200,000 gas (estimated)
└── PerpAggregator:   ~1,840,000 gas

Function Calls:
├── openPosition():      ~145,000 gas
├── closePosition():     ~60,000 gas
├── increasePosition():  ~65,000 gas
├── reducePosition():    ~65,000 gas
├── registerVenue():     ~48,000 gas
└── setOracle():         ~48,000 gas
```

## Key Features Summary

| Feature                 | Description                        | Status         |
| ----------------------- | ---------------------------------- | -------------- |
| Multi-venue aggregation | Routes to best price across venues | ✅ Implemented |
| Oracle validation       | Chainlink-style price feeds        | ✅ Implemented |
| Slippage protection     | User-defined minimum outputs       | ✅ Implemented |
| Deadline protection     | Time-bound transactions            | ✅ Implemented |
| Reentrancy protection   | Secure state changes               | ✅ Implemented |
| Pausable                | Emergency controls                 | ✅ Implemented |
| Venue management        | Dynamic venue registry             | ✅ Implemented |
| Leverage limits         | Per-venue max leverage             | ✅ Implemented |
| Position lifecycle      | Open/increase/reduce/close         | ✅ Implemented |
| Comprehensive tests     | 43 tests with fuzz testing         | ✅ Implemented |

## Future Enhancements (v2)

- [ ] Position tracking per user per venue
- [ ] Liquidation system
- [ ] Funding rate calculations
- [ ] Multi-collateral support
- [ ] Advanced routing (split orders)
- [ ] Limit orders
- [ ] Stop-loss / take-profit
- [ ] Real venue integrations (GMX, Synthetix, etc.)
