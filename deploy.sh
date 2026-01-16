#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded from .env"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Check if required variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: BASE_SEPOLIA_RPC_URL not set in .env"
    exit 1
fi

echo "🔧 Configuration:"
echo "   RPC URL: $BASE_SEPOLIA_RPC_URL"
echo "   Basescan API Key: ${BASESCAN_API_KEY:0:10}..."
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

# Deploy
echo "🚀 Deploying to Base Sepolia..."
echo ""

if [ -z "$BASESCAN_API_KEY" ]; then
    # Deploy without verification
    forge script script/Deploy.s.sol \
        --rpc-url $BASE_SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        -vvvv
else
    # Deploy with verification
    forge script script/Deploy.s.sol \
        --rpc-url $BASE_SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        --etherscan-api-key $BASESCAN_API_KEY \
        -vvvv
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Save the contract addresses from the output above"
    echo "   2. Verify contracts on Basescan: https://sepolia.basescan.org/"
    echo "   3. Test your deployment with a small transaction"
else
    echo ""
    echo "❌ Deployment failed"
    exit 1
fi
