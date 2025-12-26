# Authorization-Governed Vault System

This project implements an **authorization-governed vault system** for controlled asset withdrawals on an Ethereum-compatible blockchain.  
The system separates **fund custody** and **permission validation** into two independent on-chain contracts to improve security, correctness, and auditability.

---

## Objective

- Hold pooled ETH securely in a vault
- Allow withdrawals **only** after explicit authorization
- Ensure each authorization is used **exactly once**
- Prevent replay attacks, duplicate withdrawals, and unauthorized access
- Demonstrate secure multi-contract architecture

---

## System Architecture

The system consists of **two smart contracts** with clearly separated responsibilities.

### 1. SecureVault
- Holds pooled ETH
- Accepts deposits from any address
- Executes withdrawals only after authorization validation
- Does **not** perform cryptographic signature verification
- Emits deposit and withdrawal events

### 2. AuthorizationManager
- Validates off-chain generated withdrawal permissions
- Tracks authorization usage
- Ensures each authorization can be consumed only once
- Emits authorization consumption events

---

## Authorization Design

Each withdrawal authorization is tightly bound to:

- Vault contract address
- Blockchain network (chain ID)
- Recipient address
- Withdrawal amount
- Unique nonce (one-time identifier)

### Deterministic Message Construction

keccak256(
  abi.encode(
    vaultAddress,
    chainId,
    recipient,
    amount,
    nonce
  )
)

### This design prevents:

- Replay attacks

- Cross-chain reuse

- Cross-vault reuse

- Duplicate withdrawals


## Repository Structure

authorization-governed-vault/
├─ contracts/
│  ├─ SecureVault.sol
│  └─ AuthorizationManager.sol
├─ scripts/
│  └─ deploy.js
├─ tests/
│  └─ system.spec.js
├─ docker/
│  ├─ Dockerfile
│  └─ entrypoint.sh
├─ docker-compose.yml
└─ README.md


## Tech Stack

- Solidity
- Hardhat
- Ethers.js
- Node.js
- Docker
- Ganache (local blockchain)


## Step-by-Step Setup

### Step 1: Install Dependencies

npm install

### Step 2: Compile Smart Contracts

npx hardhat compile

### Step 3: Docker Setup (Recommended)

Run the complete local environment using Docker:

  docker-compose up --build


#### This command will:

- Start a local Ganache blockchain at http://localhost:8545

- Compile all smart contracts

- Deploy AuthorizationManager

- Deploy SecureVault with the authorization manager address

- Output deployed contract addresses and chain ID to logs


## Local Validation: Manual Authorization Flow

This section documents how authorization is generated off-chain and consumed on-chain.

---

### Step 1: Start Local Environment

docker-compose up --build

Check the logs for:

- AuthorizationManager contract address  
- SecureVault contract address  
- Network chain ID  

---

## Step 2: Deposit ETH into the Vault

Send ETH to the deployed `SecureVault` address using any funded Ganache account.

Example using Hardhat console:

await signer.sendTransaction({
  to: VAULT_ADDRESS,
  value: ethers.parseEther("1")
});

A Deposit event will be emitted.

## Step 3: Generate Off-Chain Authorization

The trusted signer (owner of `AuthorizationManager`) generates a withdrawal authorization off-chain.

Authorization parameters:

- Vault address  
- Chain ID  
- Recipient address  
- Withdrawal amount  
- Unique nonce  

const hash = ethers.solidityPackedKeccak256(
  ["address","uint256","address","uint256","uint256"],
  [vault, chainId, recipient, amount, nonce]
);

const signature = await signer.signMessage(ethers.getBytes(hash));


### Step 4: Execute Withdrawal

Call the `withdraw` function on the vault:

await vault.withdraw(
  recipient,
  amount,
  nonce,
  signature
);


Expected results:

- Authorization is validated by `AuthorizationManager`
- Authorization is marked as consumed
- ETH is transferred to the recipient
- **Withdrawal** event is emitted

---

### Step 5: Reuse Attempt (Expected Failure)

Attempting to reuse the same authorization will revert with:

Authorization already used

This confirms:

- One-time authorization enforcement  
- No duplicate withdrawals  
- Correct invariant preservation  

---

## System Guarantees

- Vault balance never becomes negative  
- Each authorization produces exactly one state transition  
- Unauthorized callers cannot trigger withdrawals  
- State updates occur before value transfer  
- Failed withdrawals revert deterministically  
- All critical actions emit observable events  

---

## Observability

The system emits events for:

- Deposits  
- Authorization consumption  
- Withdrawals  

These events provide full on-chain visibility into system behavior.

---

## Notes

- The vault never verifies cryptographic signatures  
- Authorization logic is fully isolated  
- Contracts are deployed deterministically  
- The system behaves correctly under repeated or unexpected calls  
- Initialization logic is executed exactly once  
