# Suggested Git Commits

This document outlines the logical commit structure for this project following Conventional Commits style.

## Commit 1: Project Initialization

```
chore: initialize foundry project for base perp dex aggregator

- Initialize Foundry project structure
- Configure foundry.toml for Solidity ^0.8.24
- Set up Base chain configuration
```

## Commit 2: Core Interfaces

```
feat: add core interfaces for venue and oracle integration

- Add IVenue interface with standard perp DEX methods
- Add IOracle interface for Chainlink-style price feeds
- Add IPerpAggregator interface for main aggregator contract
- Define events for position lifecycle tracking
```

## Commit 3: Venue Management

```
feat: implement venue manager for DEX registry

- Add VenueManager contract for venue registration
- Support venue metadata (max leverage, fees, name)
- Implement active/inactive venue status management
- Add owner-only access controls
- Emit events for venue lifecycle changes
```

## Commit 4: Oracle Management

```
feat: implement oracle manager for price validation

- Add OracleManager contract with Chainlink-style integration
- Implement price staleness checks (15 min max age)
- Add configurable price deviation limits (default 5%)
- Validate execution prices against oracle feeds
- Prevent price manipulation attacks
```

## Commit 5: Main Aggregator

```
feat: implement perp aggregator with venue routing

- Add PerpAggregator main contract
- Implement openPosition with best venue selection
- Implement closePosition, increasePosition, reducePosition
- Add reentrancy protection on all state-changing functions
- Implement deadline and slippage protection
- Add pausable emergency controls
- Integrate oracle price validation
- Select best venue based on price and fees
```

## Commit 6: Mock Contracts for Testing

```
test: add mock contracts for venue and oracle testing

- Add MockVenue implementing IVenue interface
- Add MockOracle implementing IOracle interface
- Support configurable prices and fees
- Enable forced revert scenarios for testing
```

## Commit 7: Oracle Manager Tests

```
test: add comprehensive oracle manager tests

- Test oracle registration and price retrieval
- Test stale price detection
- Test price deviation validation
- Test access controls
- Add fuzz tests for price validation
- Test custom deviation limits
```

## Commit 8: Venue Manager Tests

```
test: add comprehensive venue manager tests

- Test venue registration and removal
- Test venue status management
- Test active venue filtering
- Test access controls
- Test invalid input handling
- Add fuzz tests for venue parameters
```

## Commit 9: Aggregator Core Tests

```
test: add comprehensive aggregator tests

- Test full position lifecycle (open/increase/reduce/close)
- Test venue selection algorithm
- Test slippage protection
- Test deadline expiration
- Test pause/unpause functionality
- Test oracle price validation integration
- Test leverage limit enforcement
- Add fuzz tests for position parameters
```

## Commit 10: Integration Tests

```
test: add end-to-end integration tests

- Test full position lifecycle with price movements
- Test venue selection with multiple venues
- Test oracle price protection
- Test leverage limit routing
- Add detailed logging for test scenarios
```

## Commit 11: Deployment Script

```
feat: add deployment script for base mainnet

- Add Deploy.s.sol script
- Deploy VenueManager, OracleManager, PerpAggregator
- Log deployment addresses
- Support environment variable configuration
```

## Commit 12: Documentation

```
docs: add comprehensive readme and documentation

- Add README with architecture overview
- Document all contract functions and usage
- Add deployment instructions
- Document security features
- Add admin function examples
- List assumptions and future enhancements
```

## Commit 13: Cleanup

```
chore: remove default counter contracts from forge init

- Remove Counter.sol, Counter.t.sol, Counter.s.sol
- Clean up unused default files
```

---

## How to Apply These Commits

If you want to recreate this project with proper commit history:

1. Start with an empty repo
2. Apply each commit in order
3. Each commit should be atomic and focused on one feature
4. Run tests after each commit to ensure nothing breaks

## Example Git Commands

```bash
# After implementing each feature
git add <files>
git commit -m "feat: implement venue manager for DEX registry"
git push
```
