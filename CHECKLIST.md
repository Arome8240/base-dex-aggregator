# Deployment Checklist

Use this checklist to ensure a smooth deployment to Base Sepolia.

## Pre-Deployment

### Environment Setup

- [ ] Foundry installed and updated (`foundryup`)
- [ ] Repository cloned and dependencies installed (`forge install`)
- [ ] All tests passing (`forge test`)
- [ ] Contracts compile successfully (`forge build`)

### Wallet & Funds

- [ ] Wallet private key obtained (MetaMask → Account Details → Export Private Key)
- [ ] Base Sepolia ETH acquired (~0.01 ETH minimum)
  - [ ] From Coinbase faucet: https://portal.cdp.coinbase.com/products/faucet
  - [ ] Or bridged from Sepolia: https://bridge.base.org/
- [ ] Wallet balance verified on Base Sepolia

### API Keys & RPC

- [ ] RPC URL obtained (Alchemy/Infura or use public: `https://sepolia.base.org`)
- [ ] Basescan API key obtained: https://basescan.org/myapikey
- [ ] `.env` file created from `.env.example`
- [ ] `.env` file populated with:
  - [ ] `PRIVATE_KEY` (without 0x prefix)
  - [ ] `BASE_SEPOLIA_RPC_URL`
  - [ ] `BASESCAN_API_KEY`
- [ ] Environment variables loaded (`source .env`)

## Deployment

### Build & Test

- [ ] Clean build: `forge clean && forge build`
- [ ] All tests pass: `forge test`
- [ ] Contract sizes checked: `forge build --sizes`
- [ ] Gas estimates reviewed: `forge test --gas-report`

### Dry Run

- [ ] Dry run executed successfully:
  ```bash
  forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY
  ```
- [ ] Gas estimates acceptable
- [ ] No errors in simulation

### Actual Deployment

- [ ] Deployment command executed:
  ```bash
  forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    -vvvv
  ```
- [ ] All 3 contracts deployed successfully
- [ ] Transaction hashes saved
- [ ] Deployment addresses recorded:
  - [ ] VenueManager: `0x________________`
  - [ ] OracleManager: `0x________________`
  - [ ] PerpAggregator: `0x________________`

## Post-Deployment

### Verification

- [ ] Contracts verified on Basescan
  - [ ] VenueManager: https://sepolia.basescan.org/address/0x6Eb5575aF121835A95799CAE6FD3f18aA56c721C
  - [ ] OracleManager: https://sepolia.basescan.org/address/0xa720a92c391C87BFc9583258b154Ba21cb89f311
  - [ ] PerpAggregator: https://sepolia.basescan.org/address/0xA73B526e04e11E0116eb28ec0698AfDB7a487c2D
- [ ] Contract source code visible on Basescan
- [ ] Read/Write functions accessible on Basescan

### Contract State Checks

- [ ] PerpAggregator owner is correct:
  ```bash
  cast call $PERP_AGGREGATOR "owner()" --rpc-url $BASE_SEPOLIA_RPC_URL
  ```
- [ ] PerpAggregator is not paused:
  ```bash
  cast call $PERP_AGGREGATOR "paused()" --rpc-url $BASE_SEPOLIA_RPC_URL
  ```
- [ ] VenueManager and OracleManager addresses are correct in PerpAggregator

### Documentation

- [ ] Deployment addresses saved to `deployments.txt`
- [ ] Deployment date and network recorded
- [ ] Transaction hashes documented
- [ ] Deployer address recorded
- [ ] Gas costs documented

## Configuration (Optional for Testing)

### Mock Venues

- [ ] Mock venues deployed (if needed for testing)
- [ ] Mock venues registered in VenueManager
- [ ] Venue parameters configured (max leverage, fees)

### Oracles

- [ ] Mock oracles deployed (if needed for testing)
- [ ] Oracles registered in OracleManager
- [ ] Oracle prices set for test markets

### Test Transactions

- [ ] Small test position opened successfully
- [ ] Events emitted correctly
- [ ] Position closed successfully
- [ ] Gas costs acceptable

## Security

### Access Control

- [ ] Owner address is secure wallet (hardware wallet recommended)
- [ ] Private key stored securely (not in code/git)
- [ ] `.env` file is gitignored
- [ ] No sensitive data committed to repository

### Contract Security

- [ ] Contracts are pausable (emergency stop available)
- [ ] Owner can pause/unpause
- [ ] Reentrancy guards active
- [ ] Oracle validation working
- [ ] Slippage protection working

## Monitoring

### Setup Monitoring

- [ ] Basescan alerts configured for contract
- [ ] Transaction monitoring enabled
- [ ] Event logs being tracked
- [ ] Error monitoring in place

### Health Checks

- [ ] Contract balance monitored
- [ ] Owner address monitored
- [ ] Pause state monitored
- [ ] Venue status monitored

## Documentation Updates

- [ ] README updated with deployment addresses
- [ ] Frontend configuration updated (if applicable)
- [ ] API documentation updated (if applicable)
- [ ] Team notified of deployment

## Rollback Plan

### In Case of Issues

- [ ] Pause mechanism tested and ready
- [ ] Owner key accessible for emergency actions
- [ ] Backup RPC endpoints available
- [ ] Support contacts ready

## Next Steps

### Integration

- [ ] Frontend integration started
- [ ] API endpoints configured
- [ ] Web3 provider configured
- [ ] Contract ABIs exported

### Testing

- [ ] Integration tests on testnet
- [ ] User acceptance testing
- [ ] Load testing (if applicable)
- [ ] Security review

### Production Preparation

- [ ] Mainnet deployment plan created
- [ ] Security audit scheduled (recommended)
- [ ] Mainnet RPC endpoints secured
- [ ] Production monitoring setup

---

## Quick Commands Reference

```bash
# Check deployment
cast code $PERP_AGGREGATOR --rpc-url $BASE_SEPOLIA_RPC_URL

# Check owner
cast call $PERP_AGGREGATOR "owner()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Check if paused
cast call $PERP_AGGREGATOR "paused()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Check balance
cast balance YOUR_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL

# Get transaction receipt
cast receipt TX_HASH --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

**Deployment Date**: **\*\***\_\_\_**\*\***
**Deployed By**: **\*\***\_\_\_**\*\***
**Network**: Base Sepolia (Chain ID: 84532)
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete
