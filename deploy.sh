#!/bin/bash

# A modular deployment script for the Base DEX Aggregator

# --- Configuration ---
# Default network to use if none is specified
DEFAULT_NETWORK="sepolia"

# --- Functions ---
usage() {
    echo "Usage: $0 [network]"
    echo "Deploys the contracts to the specified network."
    echo ""
    echo "Arguments:"
    echo "  network    The network to deploy to (e.g., sepolia, mainnet). Defaults to '$DEFAULT_NETWORK'."
    echo ""
    echo "Examples:"
    echo "  $0                  # Deploys to sepolia"
    echo "  $0 mainnet          # Deploys to mainnet"
    echo ""
    echo "Required Environment Variables:"
    echo "  PRIVATE_KEY              Your deployer wallet private key."
    echo "  <NETWORK>_RPC_URL        RPC URL for the specified network (e.g., SEPOLIA_RPC_URL)."
    echo "  BASESCAN_API_KEY         (Optional) Your Basescan API key for contract verification."
}

# --- Script ---
# Set network from argument or use default
NETWORK=${1:-$DEFAULT_NETWORK}
echo "Selected network: $NETWORK"
echo ""

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded from .env"
else
    echo "❌ Error: .env file not found. Please create one based on .env.example."
    exit 1
fi

# Check for required PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY is not set in your .env file."
    exit 1
fi

# Construct RPC_URL variable name (e.g., SEPOLIA_RPC_URL)
RPC_URL_VAR_NAME=$(echo "${NETWORK}_RPC_URL" | awk '{print toupper($0)}')
RPC_URL="${!RPC_URL_VAR_NAME}"

# Check for network-specific RPC_URL
if [ -z "$RPC_URL" ]; then
    echo "❌ Error: $RPC_URL_VAR_NAME is not set in your .env file."
    exit 1
fi

echo "🔧 Configuration:"
echo "   RPC URL: $RPC_URL"
if [ ! -z "$BASESCAN_API_KEY" ]; then
    echo "   Basescan API Key: ${BASESCAN_API_KEY:0:5}..."
else
    echo "   Basescan API Key: Not set (verification will be skipped)"
fi
echo ""

# Build contracts
echo "🔨 Building contracts..."
forge build
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi
echo "✅ Build successful"
echo ""

# Prepare deployment command
echo "🚀 Deploying to $NETWORK..."
echo ""

FORGE_CMD=(
    "forge script script/Deploy.s.sol"
    "--rpc-url $RPC_URL"
    "--private-key $PRIVATE_KEY"
    "--broadcast"
    "-vvvv"
)

# Add verification arguments if API key is present
if [ ! -z "$BASESCAN_API_KEY" ]; then
    FORGE_CMD+=(
        "--verify"
        "--etherscan-api-key $BASESCAN_API_KEY"
    )
    VERIFY_MSG="and verifying"
else
    VERIFY_MSG="(verification skipped)"
fi

# Execute deployment
eval "${FORGE_CMD[*]}"

# --- Results ---
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful! $VERIFY_MSG"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Check the output above for your contract addresses."
    echo "   2. Interact with your contracts on the $NETWORK network."
else
    echo ""
    echo "❌ Deployment failed"
    exit 1
fi
