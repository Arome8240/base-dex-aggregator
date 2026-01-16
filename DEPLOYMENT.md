# Deployment Guide - Base Sepolia Testnet

Complete guide to deploy the Perpetual DEX Aggregator to Base Sepolia testnet.

## Prerequisites

### 1. Get Base Sepolia ETH

You need ETH on Base Sepolia for gas fees (~0.01 ETH should be enough).

**Option A: Bridge from Sepolia**

1. Get Sepolia ETH from faucet: https://sepoliafaucet.com/
2. Bridge to Base Sepolia: https://bridge.base.org/

**Option B: Direct Base Sepolia Faucets**

- Coinbase Wallet Faucet: https://portal.cdp.coinbase.com/products/faucet
- Alchemy Faucet: https://www.alchemy.com/faucets/base-sepolia
- QuickNode Faucet: https://faucet.quicknode.com/base/sepolia

### 2. Get RPC URL (Optional but Recommended)

While you can use the public RPC, a dedicated endpoint is more reliable:

**Alchemy (Recommended)**

1. Sign up: https://www.alchemy.com/
2. Create new app → Select "Base Sepolia"
3. Copy your API key
4. Your RPC: `https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY`

**Infura**

1. Sign up: https://www.infura.io/
2. Create new project
3. Enable Base Sepolia
4. Your RPC: `https://base-sepolia.infura.io/v3/YOUR_PROJECT_ID`

### 3. Get Basescan API Key (For Verification)

1. Go to: https://basescan.org/
2. Sign up for account
3. Go to: https://basescan.org/myapikey
4. Create new API key
5. Copy the key

## Setup

### 1. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your values
nano .env  # or use your preferred editor
```

Fill in your `.env` file:

```bash
# Your wallet private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Base Sepolia RPC URL
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Basescan API key for verification
BASESCAN_API_KEY=your_basescan_api_key_here
```

⚠️ **Security Warning**: Never commit your `.env` file or share your private key!

### 2. Load Environment Variables

```bash
# Load the .env file
source .env

# Verify variables are set
echo $BASE_SEPOLIA_RPC_URL
```

## Deployment Steps

### Step 1: Build Contracts

```bash
forge build
```

Expected output:

```
[⠊] Compiling...
[⠑] Compiling X files with Solc 0.8.24
[⠘] Solc 0.8.24 finished in X.XXs
Compiler run successful
```

### Step 2: Run Tests (Optional but Recommended)

```bash
forge test
```

All 43 tests should pass.

### Step 3: Dry Run Deployment

Test the deployment without broadcasting:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

This simulates the deployment and shows gas estimates.

### Step 4: Deploy to Base Sepolia

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvvv
```

**Flags explained:**

- `--broadcast`: Actually send the transactions
- `--verify`: Verify contracts on Basescan
- `--etherscan-api-key`: Your Basescan API key
- `-vvvv`: Verbose output for debugging

### Step 5: Save Deployment Addresses

The script will output:

```
=== Deployment Summary ===
VenueManager:    0x...
OracleManager:   0x...
PerpAggregator:  0x...
========================
```

**Save these addresses!** You'll need them for:

- Frontend integration
- Contract interactions
- Documentation

Create a file to track deployments:

```bash
echo "# Base Sepolia Deployment" > deployments.txt
echo "Date: $(date)" >> deployments.txt
echo "VenueManager: 0x..." >> deployments.txt
echo "OracleManager: 0x..." >> deployments.txt
echo "PerpAggregator: 0x..." >> deployments.txt
```

## Post-Deployment Setup

After deployment, you need to configure the contracts:

### 1. Register Mock Venues (For Testing)

Deploy mock venues first:

```bash
# Create a setup script
cat > script/Setup.s.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {VenueManager} from "../src/VenueManager.sol";
import {OracleManager} from "../src/OracleManager.sol";

contract Setup is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Replace with your deployed addresses
        address venueManagerAddr = vm.envAddress("VENUE_MANAGER");
        address oracleManagerAddr = vm.envAddress("ORACLE_MANAGER");

        vm.startBroadcast(deployerPrivateKey);

        VenueManager venueManager = VenueManager(venueManagerAddr);
        OracleManager oracleManager = OracleManager(oracleManagerAddr);

        // Register mock venues
        // TODO: Deploy real venue integrations

        console2.log("Setup complete!");

        vm.stopBroadcast();
    }
}
EOF
```

### 2. Verify Contracts on Basescan

If auto-verification failed, manually verify:

```bash
# Verify VenueManager
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.24 \
  0xYOUR_VENUE_MANAGER_ADDRESS \
  src/VenueManager.sol:VenueManager \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify OracleManager
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.24 \
  0xYOUR_ORACLE_MANAGER_ADDRESS \
  src/OracleManager.sol:OracleManager \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify PerpAggregator (with constructor args)
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.24 \
  --constructor-args $(cast abi-encode "constructor(address,address)" 0xVENUE_MANAGER 0xORACLE_MANAGER) \
  0xYOUR_PERP_AGGREGATOR_ADDRESS \
  src/PerpAggregator.sol:PerpAggregator \
  --etherscan-api-key $BASESCAN_API_KEY
```

### 3. Test Deployment

Interact with your deployed contracts:

```bash
# Check owner
cast call 0xYOUR_PERP_AGGREGATOR_ADDRESS "owner()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Check if paused
cast call 0xYOUR_PERP_AGGREGATOR_ADDRESS "paused()" --rpc-url $BASE_SEPOLIA_RPC_URL
```

## Troubleshooting

### Issue: "Insufficient funds"

**Solution**: Get more Base Sepolia ETH from faucets

### Issue: "Nonce too low"

**Solution**:

```bash
# Reset nonce
cast nonce YOUR_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Issue: "Verification failed"

**Solution**:

- Wait a few minutes and try again
- Check Basescan API key is correct
- Manually verify using the web interface

### Issue: "RPC error"

**Solution**:

- Check RPC URL is correct
- Try public RPC: `https://sepolia.base.org`
- Get dedicated RPC from Alchemy/Infura

### Issue: "Private key error"

**Solution**:

- Ensure no `0x` prefix in `.env`
- Check key is correct (64 hex characters)
- Ensure `.env` is loaded: `source .env`

## Verification Checklist

After deployment, verify:

- [ ] All 3 contracts deployed successfully
- [ ] Contracts verified on Basescan
- [ ] Deployment addresses saved
- [ ] Owner address is correct
- [ ] Contracts are not paused
- [ ] VenueManager and OracleManager addresses are correct in PerpAggregator

## Next Steps

1. **Register Venues**

   - Deploy or integrate real perp venues
   - Register them in VenueManager

2. **Set Up Oracles**

   - Use Chainlink price feeds on Base Sepolia
   - Register oracles in OracleManager

3. **Test Transactions**

   - Open a small test position
   - Verify events are emitted
   - Check position tracking

4. **Build Frontend**
   - Use deployed contract addresses
   - Integrate with Web3 library
   - Add UI for position management

## Useful Commands

```bash
# Check balance
cast balance YOUR_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL

# Get transaction receipt
cast receipt TX_HASH --rpc-url $BASE_SEPOLIA_RPC_URL

# Call contract function
cast call CONTRACT_ADDRESS "functionName()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Send transaction
cast send CONTRACT_ADDRESS "functionName()" --private-key $PRIVATE_KEY --rpc-url $BASE_SEPOLIA_RPC_URL

# Estimate gas
cast estimate CONTRACT_ADDRESS "functionName()" --rpc-url $BASE_SEPOLIA_RPC_URL
```

## Resources

- **Base Sepolia Explorer**: https://sepolia.basescan.org/
- **Base Docs**: https://docs.base.org/
- **Foundry Book**: https://book.getfoundry.sh/
- **Base Bridge**: https://bridge.base.org/
- **Chainlink Base Feeds**: https://docs.chain.link/data-feeds/price-feeds/addresses?network=base

## Support

If you encounter issues:

1. Check this guide thoroughly
2. Review Foundry documentation
3. Check Base Discord/Forum
4. Open GitHub issue with error details

---

**Good luck with your deployment!** 🚀
