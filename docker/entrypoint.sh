#!/bin/sh

echo "Compiling smart contracts..."
npx hardhat compile

echo "Deploying contracts..."
npx hardhat run scripts/deploy.js --network localhost

echo "Deployment complete."
tail -f /dev/null
