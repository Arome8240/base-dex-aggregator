# Deploy Right Now - Step by Step

## Option 1: Using the Deploy Script (Easiest)

```bash
# Make script executable (only needed once)
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

That's it! The script will:

- Load your `.env` file
- Build the contracts
- Deploy to Base Sepolia
- Verify on Basescan

---

## Option 2: Manual Deployment

### Step 1: Load Environment Variables

```bash
# Load .env file
source .env

# Verify they're loaded
echo $BASE_SEPOLIA_RPC_URL
```

### Step 2: Build

```bash
forge build
```

### Step 3: Deploy

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvvv
```

---

## Option 3: Using Foundry's Built-in .env Loading

Foundry can automatically load `.env` files:

```bash
forge script script/Deploy.s.sol \
  --rpc-url base-sepolia \
  --broadcast \
  --verify \
  -vvvv
```

But you need to add this to `foundry.toml` first:

```toml
[rpc_endpoints]
base-sepolia = "${BASE_SEPOLIA_RPC_URL}"

[etherscan]
base-sepolia = { key = "${BASESCAN_API_KEY}" }
```

---

## What to Expect

### During Deployment

You'll see output like:

```
✅ Environment variables loaded from .env
🔧 Configuration:
   RPC URL: https://sepolia.base.org
   Basescan API Key: YDTQ43F8HS...

🔨 Building contracts...
✅ Build successful

🚀 Deploying to Base Sepolia...

[⠊] Compiling...
No files changed, compilation skipped

Script ran successfully.

== Logs ==
  VenueManager deployed at: 0x1234...
  OracleManager deployed at: 0x5678...
  PerpAggregator deployed at: 0x9abc...

=== Deployment Summary ===
VenueManager:    0x1234...
OracleManager:   0x5678...
PerpAggregator:  0x9abc...
========================

✅ Deployment successful!
```

### Save These Addresses!

Copy the three contract addresses and save them somewhere safe.

---

## Troubleshooting

### Error: "No such file or directory"

Your `.env` file exists, but bash can't find it. Try:

```bash
# Check if .env exists
ls -la .env

# Load it explicitly
source .env

# Then deploy
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY -vvvv
```

### Error: "value is required for '--fork-url'"

The environment variable isn't loaded. Use the deploy script:

```bash
./deploy.sh
```

### Error: "Insufficient funds"

You need Base Sepolia ETH. Get it from:

- https://portal.cdp.coinbase.com/products/faucet
- https://www.alchemy.com/faucets/base-sepolia

### Error: "Invalid private key"

Check your `.env` file:

- Private key should be 64 hex characters
- No `0x` prefix
- No spaces or quotes

---

## Quick Check Before Deploying

```bash
# 1. Check your balance
cast balance YOUR_WALLET_ADDRESS --rpc-url https://sepolia.base.org

# 2. Check RPC is working
cast block-number --rpc-url https://sepolia.base.org

# 3. Verify contracts compile
forge build
```

---

## After Deployment

### 1. Verify on Basescan

Visit: https://sepolia.basescan.org/address/YOUR_CONTRACT_ADDRESS

### 2. Test the Deployment

```bash
# Check owner
cast call YOUR_PERP_AGGREGATOR_ADDRESS "owner()" --rpc-url https://sepolia.base.org

# Expected output: your wallet address
```

### 3. Save Deployment Info

```bash
# Create deployment record
cat > deployment-$(date +%Y%m%d).txt << EOF
Deployment Date: $(date)
Network:Base Sepolia (Chain ID: 84532)
Deployer: YOUR_WALLET_ADDRESS

Contract Addresses:
- VenueManager: 0x...
- OracleManager: 0x...
- PerpAggregator: 0x...

Transaction Hashes:
- VenueManager: 0x...
- OracleManager: 0x...
- PerpAggregator: 0x...
EOF
```

---

## Ready to Deploy?

Choose your method and run it! The easiest is:

```bash
./deploy.sh
```

Good luck! 🚀
